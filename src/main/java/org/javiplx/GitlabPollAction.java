package org.javiplx;

import hudson.Util;

import hudson.model.Action;
import hudson.model.AbstractProject;

import hudson.console.AnnotatedLargeText;

import org.apache.commons.jelly.XMLOutput;

import java.nio.charset.Charset;

import java.io.File;
import java.io.IOException;

/**
 * @author <a href="mailto:javiplx@gmail.com">Javier Palacios</a>
 */

/**
 * Action object for displaying the GitLab polling log.
 */
public class GitlabPollAction implements Action {

    private AbstractProject job;

    public GitlabPollAction(AbstractProject<?,?> project) {
        job = project;
    }

    public String getIconFileName() {
        return "clipboard.png";
    }

    public String getDisplayName() {
        return "Gitlab Trigger Log";
    }

    public String getUrlName() {
        return "GitlabPollLog";
    }

    public AbstractProject<?,?> getOwner() {
        return job;
    }

    public String getLog() throws IOException {
        return Util.loadFile(getLogFile());
    }

    /**
     * Writes the annotated log to the given output.
     * @since 1.350
     */
    public void writeLogTo(XMLOutput out) throws IOException {
        new AnnotatedLargeText<GitlabPollAction>(getLogFile(), Charset.defaultCharset(),true,this).writeHtmlTo(0,out.asWriter());
    }

    private File getLogFile() {
        return new File(job.getRootDir(),"gitlab-polling.log");
    }

}

