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
 * asks if you want to proceed with deletion.

If confirmed, then it continues:

 * requests deletion of the stack
 * tails the stack events, until the stack reaches a steady state.

Future development
------------------

 * probably: deletion failure prediction (for certain kinds of resources only; for example, non-empty S3 buckets)
 * maybe: advising on resources which, if deleted and manually re-created, won't get the same ID (maybe)
 * maybe: machine-readable output
 * maybe: batch mode

