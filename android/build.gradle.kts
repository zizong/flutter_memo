import com.android.build.api.dsl.CommonExtension
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
            // 使用 CommonExtension 代替 BaseExtension
            val android = project.extensions.getByType(CommonExtension::class.java)
            // 设置 compileSdkVersion（注意：某些版本是 compileSdk，我们同时设置两个）
            android.compileSdkVersion = 36
            // 如果 compileSdk 可用，也设置：
            try {
                android.compileSdk = 36
            } catch (e: Exception) {
                // 忽略，可能已设置
            }
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
