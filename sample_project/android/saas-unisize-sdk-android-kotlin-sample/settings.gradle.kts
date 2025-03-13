pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        // maven {
        //     url = uri("https://maven.pkg.github.com/Makip/unisize-sdk-android-distribute")
        //     credentials {
        //         username = System.getenv("GITHUB_USERNAME")
        //         password = System.getenv("GITHUB_TOKEN")
        //     }
        // }

        google()
        mavenCentral()
    }
}

rootProject.name = "saas-unisize-sdk-android-kotlin-sample"
include(":app")
 