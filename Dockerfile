
###########################################################################
# Jenkins Install plugin:
###########################################################################

FROM maven:3-jdk-8 as builder

RUN mkdir /workdir

WORKDIR /workdir

RUN git clone https://github.com/fcumselab/screenshotjenkinsplugin.git \
	&& \
	git clone https://github.com/fcumselab/UpdatePngToDBJenkinsPlugin.git \
	&& \
	git clone https://github.com/fcumselab/ProgEduJenkinsPlugin.git \
	&& \
	git clone https://github.com/fcumselab/AndroidScreenshotPlugin.git

RUN cd ProgEduJenkinsPlugin && mvn package
RUN cd screenshotjenkinsplugin && mvn package
RUN cd UpdatePngToDBJenkinsPlugin && mvn package
RUN cd AndroidScreenshotPlugin && mvn package

FROM jenkins/jenkins:2.263.2

USER root

ARG SDK_SETUP=true
ARG GRADLE_MAVEN=5.6.4
ENV PATH=$PATH:/opt/gradle/gradle-$GRADLE_MAVEN/bin
# Environment variables for Android SDK
ARG SDK_NAME=sdk-tools-linux-4333796
ENV ANDROID_HOME /usr/local/android-sdk-linux
ENV ANDROID_SDK_HOME /usr/local/android-sdk-linux
ENV ANDROID_AVD_HOME /root/.android/avd
ENV PATH $PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator
ARG SDK_PLATFORMS=android-28
ARG SDK_BUILD_TOOLS=28.0.3

COPY --from=builder /workdir/ProgEduJenkinsPlugin/target/jenkins-progedu.hpi /usr/share/jenkins/ref/plugins/jenkins-progedu.jpi
COPY --from=builder /workdir/screenshotjenkinsplugin/target/screenshot.hpi /usr/share/jenkins/ref/plugins/screenshot.jpi
COPY --from=builder /workdir/UpdatePngToDBJenkinsPlugin/target/progeduDB.hpi /usr/share/jenkins/ref/plugins/progeduDB.jpi
COPY --from=builder /workdir/AndroidScreenshotPlugin/target/android-screenshot.hpi /usr/share/jenkins/ref/plugins/android-screenshot.jpi

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt; \
###########################################################################
# Install Nodejs:
###########################################################################
	curl -sL https://deb.nodesource.com/setup_10.x | bash - \
	&& \
	apt-get update && apt-get install -y --no-install-recommends \
	nodejs; \
###########################################################################
# Install GRADLE and MAVEN:
###########################################################################
	apt-get install -y --no-install-recommends default-jdk maven \
	&& \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
	wget https://services.gradle.org/distributions/gradle-$GRADLE_MAVEN-bin.zip \
	&& \
	mkdir /opt/gradle \
	&& \
	unzip -d /opt/gradle gradle-$GRADLE_MAVEN-bin.zip \
	&& \
	rm gradle-$GRADLE_MAVEN-bin.zip
###########################################################################
# Install Android SDK Library:
###########################################################################
RUN if [ ${SDK_SETUP} = true ]; then \
	dpkg --add-architecture i386 \
	&& \
	apt-get update && apt-get install -y --no-install-recommends \
	libc6-dev-i386 \
	libc6-i386 \
	zlib1g:i386 \
	libstdc++6:i386 \
	libxcomposite-dev \
	libxcursor-dev:i386 \
	lib32gcc1 \
	lib32ncurses5 \
	lib32z1 \
	libqt5widgets5 \
	libpulse0:i386 \
	pulseaudio \
	libnss3-dev \
	&& \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
	&& \
###########################################################################
# Install Android SDK:
###########################################################################
	cd /usr/local \ 
	&& \
	mkdir -p $ANDROID_HOME \
	&& \
	cd $ANDROID_HOME \
	&& \
	wget https://dl.google.com/android/repository/$SDK_NAME.zip -O sdk.zip -q \
	&& \
	unzip sdk.zip >> /dev/null \
	&& \
	rm sdk.zip \
	&& \
	mkdir -p $ANDROID_HOME/.android \
	&& \
	touch $ANDROID_HOME/.android/repositories.cfg \
	&& \
###########################################################################
# Setup Android SDK:
###########################################################################
	yes | $ANDROID_HOME/tools/bin/sdkmanager "platforms;$SDK_PLATFORMS" >> /dev/null \
	&& \
	yes | $ANDROID_HOME/tools/bin/sdkmanager "build-tools;$SDK_BUILD_TOOLS" >> /dev/null \
	&& \
	yes | $ANDROID_HOME/tools/bin/sdkmanager "platform-tools" "emulator" >> /dev/null \
	&& \
	yes | $ANDROID_HOME/tools/bin/sdkmanager --include_obsolete "platforms;android-22" "system-images;android-22;default;x86" >> /dev/null \
	;fi
