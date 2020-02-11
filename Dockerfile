# This container will install Bio-Tradis from master
#
FROM debian:bullseye-slim

# Install the dependancies
RUN apt-get update -qq && apt-get install -y sudo make wget unzip zlib1g-dev cpanminus gcc bzip2 libncurses5-dev libncursesw5-dev libssl-dev r-base git libxml-libxml-perl libgd-gd2-perl bioperl bwa smalt tabix samtools locales
RUN wget https://github.com/lh3/minimap2/releases/download/v2.17/minimap2-2.17_x64-linux.tar.bz2
RUN tar xjfv minimap2-2.17_x64-linux.tar.bz2

# Set locales (required for running in Singularity)
RUN   sed -i -e 's/# \(en_GB\.UTF-8 .*\)/\1/' /etc/locale.gen && \
      touch /usr/share/locale/locale.alias && \
      locale-gen
ENV   LANG     en_GB.UTF-8
ENV   LANGUAGE en_GB:en
ENV   LC_ALL   en_GB.UTF-8

# Install R dependencies
RUN Rscript -e "install.packages('BiocManager')" -e "BiocManager::install()" -e "BiocManager::install(c('edgeR','getopt', 'MASS'))"

# Install some perl dependencies (will probably install more later after adding source code).
# It seems like we have to force installation of Xpath because the tests fail for some reason.  
# This in turn means we need to force install BioPerl as well
RUN cpanm IPC::System::Simple DateTime::Locale DateTime Dist::Zilla Moose Text::CSV ExtUtils::MakeMaker Getopt::Long Try::Tiny Exception::Class
RUN cpanm Dist::Zilla::Plugin::AutoPrereqs Dist::Zilla::Plugin::Encoding Dist::Zilla::Plugin::FileFinder::ByName Dist::Zilla::Plugin::MetaResources Dist::Zilla::Plugin::PkgVersion Dist::Zilla::Plugin::PodWeaver Dist::Zilla::Plugin::RequiresExternal Dist::Zilla::Plugin::RunExtraTests Dist::Zilla::PluginBundle::Git Dist::Zilla::PluginBundle::Starter
RUN cpanm --force XML::DOM::XPath
RUN cpanm --force Bio::Seq Bio::SeqIO

# Add source code
ADD . Bio-Tradis

# Install missing dependencies gathered from source code
# This can take a while and slow down building the docker image if we install everything this way.  
# Some known dependencies are installed earlier in the dockerfile (before adding source code) to speed up build time
WORKDIR /Bio-Tradis
RUN dzil authordeps --missing | cpanm 
RUN dzil listdeps --missing | cpanm

# Set environment
ENV PATH /Bio-Tradis/bin:/minimap2-2.17_x64-linux:$PATH
ENV PERL5LIB=/Bio-Tradis/lib:$PERL5LIB
WORKDIR /work
