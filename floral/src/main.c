/* #define DEBUG */

#include <errno.h>
#include <inttypes.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <signal.h>
#include <sys/time.h>

#include "floral.h"
#include "utils.h"
#include "main.h"
#include "thread.h"
#include "utils.h"

/*
 * Initial global state.
 */
floral_state STATE = {
  .threads = NULL,
  .current = NULL
};

/**
 * Initializes the choloros green thread library.
 *
 * Creates the initial green thread from the currently executing context. The
 * `preempt` parameters specifies whether the scheduler is preemptive or not.
 * This function should only be called once.
 *
 * @param preempt true if the scheduler should preempt, false otherwise
 */
void grn_init(bool preempt) {
  STATE.current = grn_new_thread(false);
  assert_malloc(STATE.current);
  STATE.current->status = RUNNING;

  if (preempt) {
    // FIXME: The user has requested preemption. Enable the functionality.
  }
}

/**
 * Creates a new green thread and executes `fn` inside that thread.
 *
 * Allocates and initializes a new green thread so that the parameter `fn` is
 * executed inside of the new thread. Each thread is allocated its own stack.
 * After allocating and initialization the new thread, the current thread yields
 * its execution.
 *
 * @param fn The function to execute inside a new green thread.
 *
 * @return The thread ID of the newly spawned process.
 */
int grn_spawn(grn_fn fn) {
  UNUSED(fn);

  // FIXME: Allocate a new thread, initialize its context, then yield.
  grn_thread* t1 = grn_new_thread(true);

  uint64_t* top_of_stack = (uint64_t*) (t1->stack + STACK_SIZE);
  *(--top_of_stack) = (uint64_t)fn;
  *(--top_of_stack) = (uint64_t)start_thread;
  //start_thread();
  t1->context.rsp = (uint64_t)top_of_stack;
  t1->status = READY;
  grn_yield();

  return t1->id;
}

/**
 * Garbage collects ZOMBIEd threads.
 *
 * Frees the resources for all threads marked ZOMBIE.
 */
void grn_gc() {
  // FIXME: Free the memory of zombied threads.
}

/**
 * Yields the execution time of the current thread to another thread.
 *
 * If there is at least one READY thread, this function chooses one through an
 * arbitrary search and context switches into it. The current thread is marked
 * READY if it was previous RUNNING, otherwise, its status remained unchanged.
 * The status of the thread being switched to is marked RUNNING. If no READY
 * thread is found, this function return -1. Otherwise, it returns 0.
 *
 * @return 0 if execution was yielded, -1 if no yielding occured
 */
int grn_yield() {
  // FIXME: Yield the current thread's execution time to another READY thread.
  // note that grn_exit() call grn_yield() once. Be careful.

  grn_thread* current = STATE.current;
  grn_thread* next = current;



  while( (next = next_thread(next)) != current){
      if(next->status == READY){
          if(current->status == RUNNING) {
              current->status = READY;  // this check is important, current could be Zombie.
          }
          next->status = RUNNING;
          STATE.current = next;
          grn_context_switch(&current->context, &next->context);
          return 0;
      }

  }
  return -1;




}

/**
 * Blocks until all threads are finished executing.
 *
 * TODO: Keep track of parent->children relationships so that a thread only
 * waits for the threads it spawned. TODO: Take in a list of thread IDs as a
 * parameter and wait for those threads.
 *
 * @return 0 on successful wait, nonzero otherwise
 */
int grn_wait() {
  // Loop until grn_yield returns nonzero.
  while (!grn_yield());

  return 0;
}

/**
 * Exits from the calling thread.
 *
 * If the calling thread is the initial thread, then this function exits the
 * progam. Otherwise, the calling thread is marked ZOMBIE so that it is never
 * rescheduled and is eventually garbage collected. This function never returns.
 */
void grn_exit() {
  debug("Thread %" PRId64 " is exiting.\n", STATE.current->id);
  if (STATE.current->id == 0) {
    exit(0);
  }

  STATE.current->status = ZOMBIE;
  grn_yield();
}

/**
 * For compatbility across name manglers.
 */
void _grn_exit() { grn_exit(); }

/**
 * Returns a pointer to the current thread if there is one. This pointer is only
 * valid during the lifetime of the thread.
 *
 * @return a pointer to the current thread or NULL if the library hasn't been
 * initialized
 */
grn_thread *grn_current() {
  return STATE.current;
}
