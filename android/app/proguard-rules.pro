# Firebase bileşenleri yansıma (reflection) ile kuruluyor: ComponentDiscovery,
# AndroidManifest'teki meta-data adlarından sınıfı bulup PARAMETRESİZ YAPICIYI
# çağırır. Kütüphanelerin kendi kuralı yalnız "-keep class * implements
# ComponentRegistrar" diyor — bu sınıfı korur ama üyelerini korumaz. R8, hiçbir
# kodun çağırmadığı `<init>()`'ı silince bileşen kaydolamıyor ve
# `Firebase.initializeApp` tamamen çöküyor:
#
#   NullPointerException: FirebaseCrashlytics component is not present.
#
# Bu, Crashlytics eklenirken (REV-94) release yapısında gerçekten yaşandı:
# uygulama Firebase'siz açıldı, yani giriş ve online da çalışmıyordu.
# Yapıcıyı açıkça koruyoruz — kural tüm registrar'lar için, çünkü aynı tuzak
# yarın Auth veya Firestore'da patlarsa hata yine "uygulama Firebase'siz"
# olacak.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    <init>();
}
