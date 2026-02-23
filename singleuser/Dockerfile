FROM jupyter/scipy-notebook:latest

USER ${NB_UID}

# Install the RLM library and tutorial dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copy the tutorial notebook into the default work directory
COPY --chown=${NB_UID}:${NB_GID} notebooks/ /home/jovyan/work/

WORKDIR /home/jovyan/work
