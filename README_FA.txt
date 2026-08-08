PartyForge v6 — Host -> Game selection flow

هدف:
- بعد از ساخت اتاق، Host مستقیماً فهرست بازی‌های قابل اجرا را می‌بیند.
- کد ورود اتاق همیشه بالای صفحه است.
- تعداد نفرات زنده نمایش داده می‌شود (Host هم یک نفر حساب می‌شود).
- روی همه کارت‌ها دکمه «شروع بازی» وجود دارد.
- در حالت اتاق حداقل ۲ نفر لازم است، و حداقل/حداکثر خود بازی هم رعایت می‌شود.
- اگر نفر کم باشد، دقیقاً می‌گوید چند نفر دیگر لازم است.
- Host پیام game.start را از WebSocket فعلی می‌فرستد.
- Clientهای داخل اتاق همان بازی را خودکار باز می‌کنند.
- با Back از بازی، اتصال اتاق باز می‌ماند.
- فقط بازی‌هایی در صفحه Host دیده می‌شوند که واقعاً route اجرایی /games/... دارند؛ دکمهٔ نمایشیِ بدون بازی وجود ندارد.

روش اعمال:
1) ZIP را در ریشه Repository Extract کن (کنار pubspec.yaml).
2) APPLY_ROOM_GAME_FLOW.bat را اجرا کن.
   - قبل از تغییر، Backup زمان‌دار می‌سازد.
   - فایل‌ها را تک‌به‌تک در مسیر درست کپی می‌کند.
   - فقط متد announceGameStart را به HostSessionServer اضافه می‌کند.
3) در صورت تمایل:
   powershell -ExecutionPolicy Bypass -File .\VERIFY_ROOM_GAME_FLOW.ps1
4) سپس:
   git add .
   git commit -m "Add host game selection and synchronized room start"
   git push
5) یک Run جدید در Actions -> Build PartyForge -> Run workflow اجرا کن.

توجه:
این Patch راه‌اندازی و ورود هم‌زمان به بازی را شبکه‌ای می‌کند. منطق داخلی بازی‌های فعلی همچنان همان منطق هر بازی است؛ این Patch به‌تنهایی امتیاز/State همهٔ بازی‌ها را به یک Match شبکه‌ای مشترک تبدیل نمی‌کند.
