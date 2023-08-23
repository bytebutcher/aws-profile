FROM ubuntu:22.04
RUN apt update && apt-get install -y bats curl git python3 python3-pip jq sudo
RUN pip3 install git+https://github.com/aws/aws-cli.git@v2
RUN useradd -ms /bin/bash -u 1000 app && \
    echo "app ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/app
USER app
WORKDIR /home/app/
COPY --chown=app:app . /home/app/.aws-profile/
RUN cat /home/app/.aws-profile/install | bash 
RUN echo '#!/bin/bash\nsource /home/app/.aws-profile.bash\naws-profile $@' > /home/app/entrypoint.sh && chmod +x /home/app/entrypoint.sh
ENTRYPOINT ["/home/app/entrypoint.sh"]

