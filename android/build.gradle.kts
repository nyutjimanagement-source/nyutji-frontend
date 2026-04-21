// Repository configuration moved to settings.gradle.kts
allprojects {
    buildDir = File("${rootProject.projectDir}/../build", project.name)
}
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.0")
    }
}

subprojects {
    project.evaluationDependsOn(":app")
    tasks.configureEach {
        if (name.contains("UnitTest")) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
