import com.android.build.api.dsl.CommonExtension
import java.io.File

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 强制所有 Android 子模块（包括插件）使用 compileSdk 36
subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.application") ||
            project.plugins.hasPlugin("com.android.library")) {
            val android = project.extensions.getByType(CommonExtension::class.java)
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
