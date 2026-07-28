import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystoreProperties = Properties()
val releaseKeystorePropertiesFile = rootProject.file("key.properties")
if (releaseKeystorePropertiesFile.exists()) {
    releaseKeystorePropertiesFile.inputStream().use(releaseKeystoreProperties::load)
}

val releaseSigningKeys = listOf(
    "keyAlias",
    "keyPassword",
    "storeFile",
    "storePassword",
)
val releaseStoreFile = releaseKeystoreProperties
    .getProperty("storeFile")
    ?.takeIf(String::isNotBlank)
    ?.let(project::file)
val releaseSigningReady =
    releaseKeystorePropertiesFile.exists() &&
        releaseSigningKeys.all {
            !releaseKeystoreProperties.getProperty(it).isNullOrBlank()
        } &&
        releaseStoreFile?.isFile == true
val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (releaseBuildRequested && !releaseSigningReady) {
    throw GradleException(
        "A signed release was requested, but android/key.properties or its " +
            "keystore is missing/incomplete. Production builds must never use " +
            "the Android debug signing key.",
    )
}

android {
    namespace = "lugta.nawl.com"
    // Google Play requires API 36 for new apps and updates from 31 Aug 2026.
    compileSdk = 36
    // NDK r28 produces 16 KB-aligned ELF segments by default.
    ndkVersion = "28.2.13676358"

    lint {
        // Flutter rewrites android/local.properties on Windows and escapes
        // path separators but not drive-letter colons. The file is generated,
        // ignored by source control, and Gradle parses it correctly.
        disable += "PropertyEscape"
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent once published to Google Play — must never change.
        applicationId = "lugta.nawl.com"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                keyAlias = releaseKeystoreProperties.getProperty("keyAlias")
                keyPassword = releaseKeystoreProperties.getProperty("keyPassword")
                storeFile = releaseStoreFile
                storePassword = releaseKeystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Release artifacts are always signed with the private upload key.
            signingConfigs.findByName("release")?.let {
                signingConfig = it
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    packaging {
        // Keep native libraries uncompressed. AGP 9 aligns them on 16 KB
        // boundaries in both APKs and bundles.
        jniLibs.useLegacyPackaging = false
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
