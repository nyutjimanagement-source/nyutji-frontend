// Repository configuration moved to settings.gradle.kts

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
