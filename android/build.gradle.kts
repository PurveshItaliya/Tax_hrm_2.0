allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    if (project.name == "file_picker") {
        project.apply(mapOf("plugin" to "org.jetbrains.kotlin.android"))
    }
    afterEvaluate {
        // Safe check for the android block
        val android = extensions.findByName("android")
        if (android is com.android.build.api.dsl.CommonExtension) {
            android.compileSdk = 36
            android.buildToolsVersion = "36.0.0"
            
            android.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
            android.compileOptions.targetCompatibility = JavaVersion.VERSION_17
            
            if (project.configurations.findByName("implementation") != null) {
                project.dependencies.add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
            }
        }
        project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
