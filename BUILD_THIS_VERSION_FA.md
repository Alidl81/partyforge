# ساخت نسخه 0.4.0+4

این ZIP یک پروژهٔ کامل و تمیز است؛ پوشهٔ `patch_payload` یا اسکریپت Apply ندارد.

## GitHub Actions

1. محتوای پوشه `partyforge` را در ریشه Repository قرار دهید.
2. همه فایل‌های قدیمی Repository را که در این نسخه وجود ندارند حذف کنید.
3. Commit و Push کنید.
4. در GitHub به `Actions > Build PartyForge > Run workflow` بروید و یک Run جدید اجرا کنید.
5. در صورت سبز شدن هر دو Job، Artifactهای `partyforge-android-apk` و `partyforge-windows-x64` را دانلود کنید.

Workflow با Flutter `3.44.7` اجرا می‌شود و به‌ترتیب wrapper، dependency resolution، build_runner، analyze، test و build release را انجام می‌دهد.

## نکته LAN

روی Windows در اولین Host شدن، دسترسی Firewall را برای Private networks مجاز کنید. Android و Windows باید روی یک Wi-Fi یا Hotspot مشترک باشند.
