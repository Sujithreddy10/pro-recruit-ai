import { createClient } from 'https://esm.sh/@supabase/supabase-js@2' // force redeploy // force deployment v2

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const STOP_WORDS = new Set([
  'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
  'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does',
  'will', 'would', 'should', 'could', 'this', 'that', 'these', 'those', 'we', 'you', 'i',
  'as', 'by', 'from', 'up', 'about', 'into', 'through', 'during', 'our', 'your', 'their'
])

function extractKeywords(text: string, limit = 25): string[] {
  const words = text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter(w => w.length > 3 && !STOP_WORDS.has(w))

  const freq = new Map<string, number>()
  for (const w of words) freq.set(w, (freq.get(w) ?? 0) + 1)

  return [...freq.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit)
    .map(([word]) => word)
}

function scoreGeneralQuality(resumeText: string) {
  const checks: { label: string; passed: boolean; detail: string }[] = []
  const lowerText = resumeText.toLowerCase()
  const wordCount = resumeText.trim().split(/\s+/).length

  const lengthOk = wordCount >= 150 && wordCount <= 1200
  checks.push({
    label: 'Healthy length',
    passed: lengthOk,
    detail: `${wordCount} words (ideal range: 150-1200)`,
  })

  const hasExperience = /experience|employment|work history/.test(lowerText)
  checks.push({ label: 'Experience section', passed: hasExperience, detail: hasExperience ? 'Found' : 'Not detected' })

  const hasEducation = /education|degree|university|college/.test(lowerText)
  checks.push({ label: 'Education section', passed: hasEducation, detail: hasEducation ? 'Found' : 'Not detected' })

  const hasSkills = /skills|proficient|technologies|competencies/.test(lowerText)
  checks.push({ label: 'Skills section', passed: hasSkills, detail: hasSkills ? 'Found' : 'Not detected' })

  const hasEmail = /[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/i.test(resumeText)
  checks.push({ label: 'Contact email', passed: hasEmail, detail: hasEmail ? 'Found' : 'Not detected' })

  const hasNumbers = /\d+%|\d+\+|\$\d|\d+ years?/.test(lowerText)
  checks.push({ label: 'Quantifiable achievements', passed: hasNumbers, detail: hasNumbers ? 'Found numbers/metrics' : 'No metrics detected' })

  const passedCount = checks.filter(c => c.passed).length
  const score = Math.round((passedCount / checks.length) * 100)

  return { score, checks }
}

function scoreJobMatch(resumeText: string, jobTitle: string, jobDescription: string) {
  const jobText = `${jobTitle} ${jobDescription}`
  const jobKeywords = extractKeywords(jobText, 20)
  const lowerResume = resumeText.toLowerCase()

  const matched = jobKeywords.filter(kw => lowerResume.includes(kw))
  const missing = jobKeywords.filter(kw => !lowerResume.includes(kw))

  const matchPercent = jobKeywords.length === 0
    ? 0
    : Math.round((matched.length / jobKeywords.length) * 100)

  return { matchPercent, matchedKeywords: matched, missingKeywords: missing.slice(0, 10) }
}
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { userId, jobId } = await req.json()

    if (!userId) {
      return new Response(
        JSON.stringify({ error: 'userId is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // DEBUG LOGS
    const customKey = Deno.env.get('SERVICE_ROLE_KEY')
    const stdServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const stdAnonKey = Deno.env.get('SUPABASE_ANON_KEY')

    console.log('Key Check -> SERVICE_ROLE_KEY present:', !!customKey)
    console.log('Key Check -> SUPABASE_SERVICE_ROLE_KEY present:', !!stdServiceKey)
    console.log('Key Check -> SUPABASE_ANON_KEY present:', !!stdAnonKey)

    const supabaseKey = customKey || stdServiceKey || stdAnonKey || ''

    if (!supabaseKey) {
      return new Response(
        JSON.stringify({ error: 'No valid Supabase API key found in function env.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      supabaseKey,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      }
    )

    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('resume_text')
      .eq('id', userId)
      .maybeSingle()

    if (profileError) {
      console.log('Database Query Error:', profileError)
      return new Response(
        JSON.stringify({ error: `DB Error: ${profileError.message}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!profile?.resume_text) {
      return new Response(
        JSON.stringify({ error: 'No analyzed resume text found for this user. Upload a resume first.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const general = scoreGeneralQuality(profile.resume_text)

    let jobMatch = null
    if (jobId) {
      const { data: job, error: jobError } = await supabaseAdmin
        .from('jobs')
        .select('title, description')
        .eq('id', jobId)
        .maybeSingle()

      if (!jobError && job) {
        jobMatch = scoreJobMatch(profile.resume_text, job.title ?? '', job.description ?? '')
      }
    }

    return new Response(
      JSON.stringify({ general, jobMatch }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (e) {
    return new Response(
      JSON.stringify({ error: `Unexpected error: ${e.message}` }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
