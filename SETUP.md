# दैनंदिन हिशोब — public करण्याच्या पायऱ्या

1. **Supabase project** बनवा (supabase.com, region: Mumbai).
2. **SQL Editor** मध्ये `supabase/schema.sql` ची पूर्ण सामग्री एकदा चालवा.
3. **Project Settings → API** मधून Project URL आणि publishable (anon) key घ्या आणि `config.js` मध्ये `url`, `key` भरा. `owner` आणि `contact` पण भरा (गोपनीयता धोरणात दिसतात). service_role key कुठेही टाकू नका.
4. **Authentication → Sign In / Providers → Email**: सुरुवातीला "Confirm email" बंद करा (मोफत ई-मेल तासाला मोजकेच मेल पाठवतो). "पासवर्ड विसरलात?" चालण्यासाठी नंतर Authentication → SMTP मध्ये स्वतःचा SMTP जोडा.
5. **होस्टिंग**: हे पूर्ण folder (supabase/ आणि SETUP.md सोडून चालेल) Netlify, Cloudflare Pages किंवा GitHub Pages वर टाका. HTTPS आवश्यक आहे.
6. **Authentication → URL Configuration**: Site URL आणि Redirect URL म्हणून होस्टिंगचा पत्ता टाका.
7. फोनवर पत्ता उघडा → ब्राउझर मेनू → "Add to Home screen" — app install होते.

## तपासा
- नवीन खाते तयार करा, एक हिशोब नोंदवा, Supabase च्या Table Editor मध्ये `transactions` आणि `profiles` मध्ये ओळी दिसतात का पहा.
- दुसऱ्या फोनवर/ब्राउझरमध्ये लॉगिन करून हिशोब परत येतो का पहा.
- दुसरे खाते बनवून पहिल्याचा हिशोब दिसत नाही याची खात्री करा.
