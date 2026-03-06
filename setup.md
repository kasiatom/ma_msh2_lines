## Software installation  
1) On the server there is a Conda environment, and many bioinformatic programs are available after activating the bio environment.   
   ```bash
   conda activate bio 
   ```
   After activation, the command prompt should change (it should show `(bio)` at the beginning). When you finish working, you can exit the environment using the command `conda deactivate`.  

2) If a required program is not available in the bio environment, you can install it yourself by creating a separate Conda environment.  
For example, to install **MultiQC**:  
 - Create a new environment (named `multiqc_env`) 
    ```
    conda create -n multiqc_env multiqc
    ```
 - Activate the environment  
   ```
    conda activate --stack multiqc_env
	```

   The --stack argument allows the new environment to be stacked on top of the currently active one (e.g., bio). This means that programs from the bio environment remain available while also giving access to the packages installed in multiqc_env.

 - After finishing work, you can leave the environment with:  
    ```
   conda deactivate 
   ```
   This will deactivate the most recently activated environment.

3) Using precompiled binaries  
Some programs are also distributed as ready-to-run executable binaries, which can be downloaded and used without installation.   
Example with fastp:
 ```
 wget http://opengene.org/fastp/fastp  ## download the binary
 chmod a+x ./fastp   ## make program executable 
 ./fastp  --help ## run as you run normal script
 ```

## GIT and github    
I created a public repository (`ma_msh2_lines`) where I want to keep scripts and small result files (for example: MultiQC reports, plots, summary files). Please make sure not to add large data files (such as BAM or FASTQ files) to this repository.   
 1) To be able to write to the repository, you first need to create an account on GitHub. After creating the account, send me your GitHub username so I can add you as a collaborator to the repository. Once you are added, you will be able to clone the repository, commit changes, and push updates.  
 2) Setting the access to github in Visual Studio Code   
    - Generate a GitHub-specific SSH key. Open a terminal in VS Code and run:  

	   ```
	  ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/github_id  
	   ```     
      Do not add passphase (just press two times Entter during key generation).

	- Copy the public key and add it to your github account  
	  ``` 
	  cat ~/.ssh/github_id.pub 
	  ```
	  Copy the full output to your clipboard. Go to GitHub → Settings → SSH and GPG keys → New SSH key. Paste the public key (from clipboard) and give it a name like VSCode GitHub Key.    
	-  Add the following lines to the config file on server `~/.ssh/config`  (if you do not have the config file - create it. Make sure, that it is located in the `~/.ssh/` directory).
	    ```
	    Host github.com
           User git
           HostName github.com
           IdentityFile ~/.ssh/github_id  
	
	    ```	   
	- Test connection  
		```
		ssh -T git@github.com
		``` 
      You should see something like:   `Hi username! You've successfully authenticated...`. In case of problemms - contact me.     
    

3) Working with the git repository. 
Start by cloning the repository to server:
```
 git clone git@github.com:kasiatom/ma_msh2_lines.git
```  
In Visual Studio Code, a Git repository looks like a regular folder. To add changes and update the online version on GitHub, follow these steps:
   -  **Open the Git folder**: In VS Code, go to File → Open Folder and select the folder that contains the Git repository (`ma_msh2_lines`). This ensures VS Code recognizes it as a Git project.

   -  **Stage your changes**: Open the Source Control panel (icon with a branch on the left). You will see a list of changed files. Click `+` next to each file to stage it, or click `+` next to Changes to stage all files.  
   - **Commit the changes**: In the Message box at the top of the Source Control panel, type a commit message describing your changes, e.g., "Add analysis script". Click the `✔` Commit button.
    - **Synchronize with GitHub**: Click the Synchronize Changes button in the Source Control panel (circular arrows). This will push your commits to GitHub and pull any updates from the remote repository at the same time.