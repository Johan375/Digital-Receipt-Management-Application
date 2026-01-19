allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "11"
        }
    }

    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "11"
        targetCompatibility = "11"
    }
    
    afterEvaluate {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null) {
            // Force Java 11 compatibility across all plugins
            android.compileOptions.sourceCompatibility = JavaVersion.VERSION_11
            android.compileOptions.targetCompatibility = JavaVersion.VERSION_11

            // FIX FOR THE "NAMESPACE NOT SPECIFIED" ERROR
            if (android.namespace == null) {
                // If it's the edge_detection plugin, give it its specific namespace
                if (project.name == "edge_detection") {
                    android.namespace = "com.sample.edgedetection"
                } else {
                    // For other plugins, fallback to their group name
                    android.namespace = project.group.toString()
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
