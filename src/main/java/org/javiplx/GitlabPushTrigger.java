package org.javiplx;

import hudson.Extension;

import hudson.util.SequentialExecutionQueue;
import hudson.util.StreamTaskListener;

import hudson.model.AbstractProject;
import hudson.model.Item;

import hudson.triggers.Trigger;
import hudson.triggers.TriggerDescriptor;

import jenkins.model.Jenkins;

import java.io.IOException;

import java.util.logging.Level;
import java.util.logging.Logger;

import org.kohsuke.stapler.DataBoundConstructor;

/**
 * @author <a href="mailto:javiplx@gmail.com">Javier Palacios</a>
 */

public class GitlabPushTrigger extends Trigger<AbstractProject<?,?>> {

    private static final Logger LOGGER = Logger.getLogger(GitlabPushTrigger.class.getName());

    @DataBoundConstructor
    public GitlabPushTrigger() {
        super();
    }

    /**
     * Called when a POST is made.
     */
    @Deprecated
    public void onPost() {
        onPost("");
    }

    /**
     * Called when a POST is made.
     */
    public void onPost(String triggeredByUser) {
        getDescriptor().queue.execute(new Runnable() {
            public void run() {
                try {
                    StreamTaskListener listener = new StreamTaskListener();
                    boolean result = job.poll(listener).hasChanges();
                    listener.close();
                } catch (IOException e) {
                    LOGGER.log(Level.SEVERE,"Failed to record SCM polling",e);
                }
            }
        });
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

