#include <stdio.h>
#include <syslog.h>
#include <errno.h>
#include <string.h>

int main (int argc, char *argv[])
{
    openlog("logs_from_writer_c_assignment2",0,LOG_USER);
    
    if(argc != 3)
    {
        fprintf(stderr, "Error: invalid number of arguments. It should be 2: directory path+filename and string content\n");
        syslog(LOG_ERR,"Invalid Number of arguments: %d",argc);
        closelog();
        return 1;
    }
 
    char *writefile = argv[1];
    char *writestr  = argv[2];

    //Assuming the directory already exists

    //Truncate file to zero length or create text file for writing.  
    //The stream is positioned at the beginning of the file.
    FILE *fp = fopen(writefile,"w"); 
    if(fp==NULL)
    {
        fprintf(stderr, "Error: couldn't create the file %s: %s\n", writefile, strerror(errno));
        syslog(LOG_ERR,"Couldn't create the file %s: %s", writefile, strerror(errno));
        closelog();
        return 1;
    }
    
    if(fprintf(fp,"%s", writestr) < 0)
    {
        fprintf(stderr, "Error writing content to file %s :%s\n",writefile,strerror(errno));
        syslog(LOG_ERR,"Couldn't write content to file %s :%s",writefile,strerror(errno));
        fclose(fp);
        closelog();
        return 1;
    }
    
    syslog(LOG_DEBUG,"Writing %s to %s",writestr,writefile);
    
    fclose(fp);
    closelog();
    return 0;
}
