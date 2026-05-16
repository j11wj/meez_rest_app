buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // firebase_core يحتاج javawriter في AGP classloader
        classpath("com.android.tools.build:gradle:8.6.1")
        classpath("com.squareup:javawriter:2.5.1")
    }
}

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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
