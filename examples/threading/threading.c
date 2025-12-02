#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <errno.h> 
#include <string.h> 

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

// Function to create a blocking delay in milliseconds
bool msleep(long milliseconds) {
    struct timespec ts;
    int res;

    if (milliseconds < 0) {
        // Handle error: Negative milliseconds not allowed
        return false;
    }

    ts.tv_sec = milliseconds / 1000; // Seconds part of the delay
    ts.tv_nsec = (milliseconds % 1000) * 1000000; // Nanoseconds part of the delay

    do {
        res = nanosleep(&ts, &ts); // Attempt to sleep, remaining time stored in ts if interrupted
    } while (res == -1 && errno == EINTR); // Continue if interrupted by a signal
    
    return true;
}


void* threadfunc(void* thread_param)
{
	printf("threadfunc\n");

    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    
    struct thread_data * param_ptr;
    param_ptr = ( struct thread_data * ) thread_param;
    
    
    unsigned int wait_take_ms    = param_ptr->wait_to_obtain_ms;
    unsigned int wait_release_ms = param_ptr->wait_to_release_ms;
    int ret;
    
    printf("params read\n");
    printf("wait take: %d\n",wait_take_ms);
    printf("wait delay: %d\n",wait_release_ms);
    
    
    param_ptr->thread_complete_success = false;
	if(msleep((long)wait_take_ms)==false)
	{
		ERROR_LOG("Error in wait function");
		return thread_param;
	}
	
	printf("First wait finished\n");
	
	ret = pthread_mutex_lock(param_ptr->mutex);
	
	if(ret!=0)
	{
		errno=ret;
		ERROR_LOG("Mutex could not be taken: %s\n",strerror(errno));
		return thread_param;
	}
	
	printf("Mutex locked\n");

	if(msleep((long)wait_release_ms)==false)
	{
		return thread_param;
	}
    
    printf("Second wait finished\n");
    
	ret = pthread_mutex_unlock(param_ptr->mutex);
	
	if(ret!=0)
	{
		errno=ret;
		ERROR_LOG("Mutex could not be released: %s\n",strerror(errno));
		return thread_param;
	}
    
    printf("Mutex unlocked\n");
    
    param_ptr->thread_complete_success = true;
    
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */   
         
    struct thread_data *data = malloc(sizeof(struct thread_data));
    if (!data)
    {
    	ERROR_LOG("Could not allocate memory for new thread\n");
    	return false;
    }

	data->wait_to_obtain_ms=wait_to_obtain_ms;
	data->wait_to_release_ms=wait_to_release_ms;
	data->mutex = mutex;
	data->thread_complete_success = false;
	
	pthread_t tid;
	pthread_attr_t attr;
	 // Initialize attributes
    pthread_attr_init(&attr);
    // Set thread to detached state
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);

    int rc = pthread_create(&tid, &attr, threadfunc, data);
    
    pthread_attr_destroy(&attr);

    if (rc != 0) {
        errno = rc;
        ERROR_LOG("pthread_create failed: %s\n",strerror(errno));
        free(data);
        return false;
    }

	*thread = tid;
     
    return true;
}

