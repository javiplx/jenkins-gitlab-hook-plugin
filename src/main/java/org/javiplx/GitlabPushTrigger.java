package org.javiplx;

import hudson.Extension;
import hudson.Util;

import hudson.console.AnnotatedLargeText;

import hudson.util.SequentialExecutionQueue;
import hudson.util.StreamTaskListener;

import hudson.model.AbstractProject;
import hudson.model.Action;
import hudson.model.Item;

import hudson.triggers.Trigger;
import hudson.triggers.TriggerDescriptor;
import hudson.triggers.SCMTrigger.SCMTriggerCause;

import jenkins.model.Jenkins;

import java.util.Collection;
import java.util.Collections;
import java.io.File;
import java.io.IOException;

import java.util.logging.Level;
import java.util.logging.Logger;

import java.nio.charset.Charset;

import org.kohsuke.stapler.DataBoundConstructor;

import org.apache.commons.jelly.XMLOutput;

/**
 * @author <a href="mailto:javiplx@gmail.com">Javier Palacios</a>
 */

public class GitlabPushTrigger extends Trigger<AbstractProject<?,?>> {

    private static final Logger LOGGER = Logger.getLogger(GitlabPushTrigger.class.getName());

    @DataBoundConstructor
    public GitlabPushTrigger() {
        super();
    }

    public void doPollAndRun(final String triggeredBy) {
LOGGER.warning("doPollAndRun "+triggeredBy);
        getDescriptor().queue.execute(new Runnable() {
            public void run() {
                try {
                    StreamTaskListener listener = new StreamTaskListener(getLogFile());
                    boolean result = job.poll(listener).hasChanges();
                    listener.close();
LOGGER.log(Level.SEVERE,"doPollAndRun did produce "+result);
                    if (result) {
                        SCMTriggerCause cause;
                        try {
                            cause = new SCMTriggerCause(Util.loadFile(getLogFile()));
                        } catch (IOException e) {
                            LOGGER.log(Level.SEVERE,"Canot create cause from poll log",e);
                            cause = new SCMTriggerCause(triggeredBy);
                        }
                        if (job.scheduleBuild(job.getQuietPeriod(), cause)) {
                            String name = " #"+job.getNextBuildNumber();
                            LOGGER.info("SCM changes detected in "+ job.getName()+". Triggering "+name);
                        } else {
                            LOGGER.info("SCM changes detected in "+ job.getName()+". Job is already in the queue");
                        }
                    } else {
                        LOGGER.info("No SCM changes detected in "+ job.getName());
                    }
                } catch (IOException e) {
                    LOGGER.log(Level.SEVERE,"Failed to record SCM polling",e);
} catch (Exception e) {
LOGGER.log(Level.SEVERE,"OTra excepcion rarita",e);
                }
            }
        });
LOGGER.log(Level.SEVERE,"doPollAndRun "+triggeredBy);
    }

    public File getLogFile() {
        return new File(job.getRootDir(),"gitlab-polling.log");
    }

    @Override
    public Collection<? extends Action> getProjectActions() {
        return Collections.singleton(new GitlabPollAction());
    }

    /**
     * Action object for {@link Project}. Used to display the polling log.
     */
    public final class GitlabPollAction implements Action {

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

    }

    @Override
    public DescriptorImpl getDescriptor() {
        return (DescriptorImpl)super.getDescriptor();
    }

    @Extension
    public static class DescriptorImpl extends TriggerDescriptor {

        private transient final SequentialExecutionQueue queue = new SequentialExecutionQueue(Jenkins.MasterComputer.threadPoolForRemoting);

        @Override
        public boolean isApplicable(Item item) {
            return item instanceof AbstractProject;
        }

        @Override
        public String getDisplayName() {
            return "Trigger when changes are pushed to GitLab";
        }

    }

}

