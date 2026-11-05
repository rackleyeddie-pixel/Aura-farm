# Aura Farm multiplayer setup
1. Create a Supabase project at https://supabase.com/dashboard.
2. In SQL Editor run the complete contents of supabase-schema.sql.
3. In Project Settings → API, copy Project URL and the publishable/anon key into supabase-config.js. NEVER use a secret/service_role key.
4. In Authentication → URL Configuration, set Site URL to https://rackleyeddie-pixel.github.io/Aura-farm/ and add https://rackleyeddie-pixel.github.io/Aura-farm/** as an allowed redirect URL.
5. In GitHub repository Settings → Pages, deploy main / root.
6. Open multiplayer.html and create an account. If email confirmation is enabled, confirm your email first.

Security: Profiles are private to their owners. League details and awards are visible only to league members. Invite code redemption is via security-definer RPC; random codes are 10 hex characters. No public awards insertion is allowed. Real votes, verified point awarding, member name visibility, moderation, and video uploads are NOT yet implemented. Current leaderboard starts at zero.
