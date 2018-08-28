# OpenShift Spring Boot S2I

## Builder Image
The following tables describes the files used in this image.

| File                   | Required? | Description                                                  |
|------------------------|-----------|--------------------------------------------------------------|
| Dockerfile             | Yes       | Defines the base builder image                               |
| s2i/bin/assemble       | Yes       | Script that builds the application                           |
| s2i/bin/usage          | No        | Script that prints the usage of the builder                  |
| s2i/bin/run            | Yes       | Script that runs the application                             |
| s2i/bin/save-artifacts | No        | Script for incremental builds that saves the built artifacts |
| test/run               | No        | Test script for the builder image                            |
| test/test-app          | Yes       | Test application source code                                 |

### Dockerfile
Builds the builder image itself, installing Maven and Gradle and using OpenJDK as base image.


### S2I scripts
Called by OpenShift for the lifecycle of the application.


#### assemble
- Copies the Spring Boot Application source from `/tmp/src` to `/opt/app-root/src`
- Determines the build type from the BUILD_TYPE environment variable
- Executes a build of the application using the determined build typen, if a `pom.xml` is detected
- The build artifact is copied to `/opt/openshift` and a new image with the Spring Boot Application for OpenShift is created
- To support deployment of already built Spring Boot JAR applications in OpenShift a runtime image is created when no `pom.xml` is detected. The JAR must be present in the `/tmp/src` directory.

To reduce build time, any saved artifacts from the previous image build are restored.

#### run
The *run* script is used to start/run the Spring Boot application in OpenShift.

#### save-artifacts (optional)
The *save-artifacts* script allows a new build to reuse content (dependencies) from a previous version of the application image.


### Create the Spring Boot Application S2I builder image
The following command will create a S2I builder image named **spring-boot** based on the Dockerfile.
Use the OpenShift Docker, f.e. `eval $(minishift docker-env)`

```
docker build -t spring-boot .
```

### Creating the *Application Container Image*
The application container image contains the built application binary which is layered on top of the builder (base) image.  The following command will create the application container image:

**Usage:**
```
s2i build <location of source code> <S2I builder image name> <application container image name>
```

```
s2i build test/test-app spring-boot boot-app
---> Building and installing application from source...
```
Based on the logic defined in the *assemble* script, s2i will create an application container image using the supplied S2I builder image and the application source code from the *test/test-app* directory.

### Running the application container image
Running the application image is as simple as invoking the docker run command:
```
docker run -d -p 8080:8080 boot-app
```
The application *boot-app*, should now be accessible at  [http://localhost:8080](http://localhost:8080).

### Using the saved artifacts script
Rebuilding the application using the saved artifacts can be accomplished using the following command:
```
s2i build --incremental=true test/test-app spring-boot boot-app
---> Restoring build artifacts...
---> Building and installing application from source...
```
This will run the *save-artifacts* script which includes the code to backup the currently running application dependencies. When the application container image is built next time, the saved application dependencies will be re-used to build the application.

## Using the OpenShift Spring Boot Application S2I builder image

Create the S2I builder image and push it to the integrated docker registry for the current project:

```
oc new-build --strategy=docker --name=spring-boot https://github.com/trion-development/openshift-spring-boot-s2i.git
```

It can now be used for a build

```
oc new-build spring-boot~https://github.com/trion-development/spring-boot-rest-sample.git
```

To be able to use it for creating deployment through the UI upload the template to the current project:

```
curl -Ssl https://raw.githubusercontent.com/trion-development/openshift-spring-boot-s2i/master/spring-boot-s2i.json | oc create -f -
```

Open the OpenShift web console (Browser UI) and open the current project.
Click "Add to Project" in the upper right, choose "Select from project" and use the "spring-boot" template.
Specify the application details.

After clicking 'create' the following steps will be performed:

- Application build
- Creation of application container image
- Image push to OpenShift Docker Registry
- Creation of a deployment of the applicatoin as a pod
