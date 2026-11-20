// Pontifex settings. Edit the values between the quotes, then commit this file on GitHub.
window.PX_CONFIG = {
  // From Supabase: Project Settings > API
  supabaseUrl: "https://hzqoblmdamdenfxhegth.supabase.co",            // e.g. https://abcdxyz.supabase.co
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6cW9ibG1kYW1kZW5meGhlZ3RoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUwNTMwMjEsImV4cCI6MjExMDYyOTAyMX0.khz9gXgPyq4HxLiWWU6mXW-fxclYRgYq13SHAOmQuc0",            // the anon / publishable key (never the secret or service_role key)

  // Your Google Form for registration (students use the same email they sign in with)
  registrationFormUrl: "https://forms.gle/fYLytYdmtNBRRPjM6",    // e.g. https://forms.gle/xxxx

  // Billing: students see these on the Billing page
  upgradeUrl: "https://forms.gle/fYLytYdmtNBRRPjM6",             // your payment page, or a Messenger / Viber / email link
  upgradeNote: ""             // e.g. "GCash 09xx xxx xxxx. Send proof of payment with your account email."

  // Optional: change plan names, prices, and days. Format: [id, name, price, period, days]
  // , plans: [["monthly","Monthly","₱299","per month",30],["season","Review-season pass","₱1,499","6 months",183]]
};
