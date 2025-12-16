# vSphere Stress Test/Burn-In VM Build Script

This is a simple script that runs a few processes on top of ubuntu in order to simulate high **CPU/Memory/DiskIO**. This requires sizing for the physical CPU/Memory of your host. The default is sized for a 24 physical core CPU and 256GB memory. 

This does not attempt any test on hyper-threading or disk blocks -- just a burn-in test so that you know your vSphere host(s) have had some significant load. 

**Warning:** this doesn't stop. You have to stop the process or the VM to free up the resources again. Also, this is likely to give your historic metrics some skew, but it's designed for a new cluster burn-in. 


# Files

The main buildStressTest is designed for a server with 24 Core CPU's and 256GB memory.
The buildStressTest-mini script is a proof of concept for a vm running on a laptop/desktop if you want to give this a try without actually putting real hardware through it's paces.

# Suggestions? 

If there's something you'd like to see on this, please let me know. This will never get overbuilt. Simple, purpose-built for one thing.