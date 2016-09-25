cfn-delete-stack-helper
=======================

A tool to help with the deletion of AWS CloudFormation stacks.

Usage:

```
  cfn-delete-stack-helper STACK_NAME
```

(or you can use a stack ARN).

What it does
------------

 * shows the current state of the stack;
 * shows the current state of each of the stack's resources;
 * highlights which resources are likely to be affected if you proceed
   (i.e. those resources which have not already been deleted)
 * checks to see if there any reasons (that it knows of) why those deletions
   will fail
 * asks if you want to proceed with deletion.

If confirmed, then it continues:

 * requests deletion of the stack
 * tails the stack events, until the stack reaches a steady state.

Permissions
-----------

Assumes that you have permission to do everything required.  As well as
cloudformation:DeleteStack (obviously), the required permissions include
Get/List/Describe calls for various services.

Configuration
-------------

Uses the default ruby AWS SDK settings, hence respects environment variables
including $AWS_REGION, $AWS_ACCESS_KEY_ID, $AWS_SECRET_ACCESS_KEY and others.
Additionally, respects $https_proxy.

Future development
------------------

 * maybe: more failure prediction
 * maybe: advising on resources which, if deleted (and then you wanted to repair the damage by manually re-creating them), won't get the same ID
 * maybe: machine-readable output
 * maybe: batch mode

