# ساخت PartyForge بدون نصب Flutter روی کامپیوتر

این مخزن دارای Workflow آمادهٔ GitHub Actions است که روی Runner رسمی لینوکس، APK اندروید و روی Runner رسمی ویندوز، بستهٔ Windows x64 را می‌سازد.

## مراحل

1. یک Repository جدید در GitHub ایجاد کنید.
2. تمام محتویات این پوشه را در Repository قرار دهید و Push کنید.
3. در GitHub به تب **Actions** بروید.
4. Workflow با نام **Build PartyForge** را انتخاب کنید.
5. روی **Run workflow** و سپس دکمهٔ سبز **Run workflow** بزنید.
6. پس از پایان اجرا، در پایین صفحهٔ همان Run بخش **Artifacts** ظاهر می‌شود.

خروجی‌ها:

- `partyforge-android-apk`: شامل `app-release.apk` و SHA-256 آن
- `partyforge-windows-x64`: شامل ZIP برنامهٔ ویندوز و SHA-256 آن

برای اجرای نسخهٔ ویندوز، ZIP را کامل Extract کنید و فایل اجرایی داخل آن را اجرا کنید. فایل‌های DLL و پوشهٔ `data` باید کنار EXE باقی بمانند.

## نکتهٔ مهم

Workflow ابتدا `flutter analyze` و `flutter test` را اجرا می‌کند. اگر کد خطای کامپایل یا تست داشته باشد، Build متوقف می‌شود و Log دقیق در همان صفحه نمایش داده خواهد شد. این رفتار عمدی است تا فایل خراب به‌عنوان Release تحویل نشود.
