---
title: "Modifying memory of a running process in Linux"
date: 2019-06-26
layout: post
comments: false
tags:
  - linux
  - memory
  - c
  - process
---

Everything said in this post is based on my half-understanding of how memory works,
especially in Linux. There are certainly going to be parts in this post that are misunderstood
by me. Don't rely on this post for your homework and take everything in this post with a
grain of salt. However, I hope to continue to refine the content in this post as I understand
more about how a computer works. Consider this as a disclaimer. That said, let's begin!

I've been trying out 6502 and x86 Assembly to learn some basic reverse engineering and also
to learn think in these low-level programming languages, hopefully to understand more of how
everything works under-the-hood. So I thought what better than to pun some other process's
memory. I figured I'll try to modify some stuff assigned to memory by one process from some second
process. I know Windows has tools like [Cheat Engine](https://github.com/cheat-engine/cheat-engine)
while Linux has [scanmem](https://github.com/scanmem/scanmem).
I still wanted to create my own tiny little program which would be enough to demonstrate how
these big tools worked at their heart.

Most modern Operating Systems have [ASLR (Address Space Layout Randomization)](https://en.wikipedia.org/wiki/Address_space_layout_randomization)
turned on
by default which can help prevent many [buffer overflow](https://en.wikipedia.org/wiki/Buffer_overflow)
and code injection attacks. These
attacks if successful could possibly allow the user to gain access to sensitive information
not intended for access to the end user. Although, I've tried Cheat Engine and to my knowledge
popular debuggers still allow for a way to access and modify the disassembled code of a binary
when loaded into memory. They also have a way to watch for code whenever a specified memory
location is accessed by the concerned process, so I'm not completely sure whether these
debuggers somehow workaround ASLR or if this completely unrelated. Irrespective of this, to
make things not more complicated, we'll already know the address of the memory location we wish
to modify, as you'll see later.

From now on, let's refer to a primary innocent process as Process A and the secondary process
which attempts to hack into the memory of Process A as Process B. In Linux, we have a system call
[`ptrace`](http://man7.org/linux/man-pages/man2/ptrace.2.html) which acts as a middle man between
Process B and the memory of Process A. One cannot
directly read or write to the memory of another independent process without ptrace for some
reason I don't understand. My current guess is that it's there so that a process doesn't
unintentionally messes up with the memory of some other process. So, if you see someone with ptrace
it's probably because they ought to either save the world from extinction or be the very cause
itself. Similar in Windows you have [`ReadProcessMemory`](https://docs.microsoft.com/en-us/windows/desktop/api/memoryapi/nf-memoryapi-readprocessmemory)
and [`WriteProcessMemory`](https://docs.microsoft.com/en-us/windows/desktop/api/memoryapi/nf-memoryapi-writeprocessmemory)
functions available in Windows API acting as the middle man.

Let's say we have this simple C code:
```c
// process_a.c
#include <stdio.h>
#include <unistd.h>

int main() {
    int n = 10;

    printf("%d\n", n);
    printf("%p\n", &n);

    sleep(25);
    printf("%d\n", n);
    printf("%p\n", &n);
    return 0;
}
```

All it does is:
  - assign a variable a value
  - display the variable's value and its location in memory
  - sleep the main thread for a while
  - display the variable's value and its location in memory again


Let's run it:
```console
$ gcc process_a.c -o process_a && ./process_a
10
0x7fffcfd52924
10
0x7fffcfd52924
```

This is our Process A. Our goal is to have a Process B change the value of the assigned variable to
something like `20` while the main thread is sleeping. If we succeed, it should show us the value `20`
after waking up from sleep while the memory location should remain the same.

I've only tried this on Linux so that's what I'll be talking about. As I mentioned earlier,
you need to fire the ptrace system call and you can do that natively via C. So, what we'll
do is write another program which will act as Process B. To overwrite the memory of another process
in Linux, you need to know three things - the PID of the Process A, the memory location to be
modified, and obviously the data you need to overwrite with. It's easy to know the PID of a process
in Linux, and we can know the memory location of the variable since our Process A prints the variable's
memory location itself. The data can be anything, I'll use `20` for the purpose of this post.

Here's how we'll use `ptrace`:
```c
// process_b.c
#include <sys/ptrace.h>
#include <stdio.h>

int main() {
    int pid = 5831;
    int *address = (int *)0x7fffcfd52924;
    int data = 20;

    ptrace(PTRACE_ATTACH, pid, NULL, NULL);
    perror("attach");
    ptrace(PTRACE_POKEDATA, pid, address, data);
    perror("pokedata");
    ptrace(PTRACE_DETACH, pid, NULL, NULL);
    perror("detach");

    return 0;
}
```

The code is pretty self-explanatory - you attach to the process, write data to a memory address and
detach.

Another thing to take care is that the PID and the memory of any process A are allotted at execution.
As far as I know, one cannot predict the PID and where in memory a process will go live, before execution
of the concerned program. There are probably ways to automate this after the concerned process is
executed but let's avoid complicating the code. So here's our plan, we'll execute the Process A and
then we're going to grab its PID manually and update our Process B's source accordingly. Finally,
we're going to compile and execute our Process B. If we are fast enough and make it through all
of this while Process A is in the middle of its sleep, we would have successfully overwritten Process
A's memory and it should be visible when it wakes up from sleep to display the value!


Let's do it step wise:

In a terminal, run:
```console
$ ./process_a &; fg
```

You should get something like this:
```console
[1] 32555
[1]  + 32555 running    ./process_a
10
0x7fffcfd52924
```

The main thread will now go in sleep mode for another 25 seconds. By executing the program in
background mode, we also get its PID, which in my case is `32555`. We could then just call it
in the foreground with `fg`. Also, the memory address is `0x7fffcfd52924`. Now, we have
everything we need to call `ptrace`.

In a new terminal, edit `process_b.c`'s variables with what you got from above. For me, I'll replace
the variables with:
```c
    int pid = 32555;
    int *address = (int *)0x7fffcfd52924;
    int data = 20;
```

Now compile and execute the code with:
```
$ gcc process_b.c -o process_b && sudo ./process_b
```
Only root can modify another process's memory, so you'll need `sudo` to run the executable
generated.

If everything goes fine and you were able to make it this far while Process A was asleep, you
should get output similar to this:
```console
attach: Success
pokedata: Success
detach: Success
```

That's it! Now when Process A completes its sleep: it should look something like this:
```console
[1] 32555
[1]  + 32555 running    ./process_a
10
0x7fffcfd52924
20
0x7fffcfd52924
*** stack smashing detected ***: <unknown> terminated
[1]  + 32555 abort      ./process_a
```

Yay, The value just got to 20. Awesome!!


Now if you see the last few lines, you'll noticed this weird error I dunno much about:
```console
*** stack smashing detected ***: <unknown> terminated
[1]  + 32555 abort      ./process_a
```

Turns out I got rid of it by simply assigning a pointer to our variable in Process A.
What I mean is replace:
```c
    int n = 10;
```
with
```c
    int n = 10;
    int *ptr = &n;
```

For some reason, this works and I no longer smash the stack while hacking into Process A's
memory.

Well, this is the heart of how a memory editor works underneath. One could now imagine
how this can scale into bigger beasts like Cheat Engine and scanmem as I talked in the
first paragraph.
