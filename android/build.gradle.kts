// Repository configuration moved to settings.gradle.kts
allprojects {
    layout.buildDirectory.set(file("${rootProject.projectDir}/../build/${project.name}"))
}
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
    }
}

subprojects {
    project.evaluationDependsOn(":app")
    tasks.configureEach {
        if (name.contains("UnitTest")) {
            enabled = false
        }
    }
    
    // Paksa Kotlin Compiler 2.1.0 ke seluruh third party plugin agar tidak berebut versi 2.3.10
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.1.0")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
