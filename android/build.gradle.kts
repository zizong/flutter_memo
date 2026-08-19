import com.android.build.gradle.BaseExtension
import java.io.File
import java.util.Properties
import java.io.FileInputStream

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.application") ||
            project.plugins.hasPlugin("com.android.library")) {
            // 显式获取 android 扩展并设置 compileSdk
            val android = project.extensions.getByName("android") as BaseExtension
            android.compileSdk = 36
        }
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
