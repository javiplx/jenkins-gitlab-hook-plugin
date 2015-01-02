package org.javiplx;

import hudson.Extension;

import hudson.model.AbstractProject;
import hudson.model.Item;

import hudson.triggers.Trigger;
import hudson.triggers.TriggerDescriptor;

import org.kohsuke.stapler.DataBoundConstructor;

/**
 * @author <a href="mailto:javiplx@gmail.com">Javier Palacios</a>
 */

public class GitlabPushTrigger extends Trigger<AbstractProject<?,?>> {

    @DataBoundConstructor 
    public GitlabPushTrigger() { 
        super();
    } 

    @Override
    public DescriptorImpl getDescriptor() {
        return (DescriptorImpl)super.getDescriptor();
    }

    @Extension
    public static class DescriptorImpl extends TriggerDescriptor {

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

