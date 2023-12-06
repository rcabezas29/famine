# famine

The aim of this project is to learn the basics of self-replicating virsus. It has no malicious code inside it but just the coding so that it replicates its own code inside another binary files and a signature with our names.

The `famine` virus will only affect two test folders: `/tmp/test` and `/tmp/test2`.

It will look for the ELF files present in the folders specified above, turns the PT_NOTE [phdr](https://man7.org/linux/man-pages/man5/elf.5.html) flag into a PT_LOAD, so that some code can be executed inside. It changes then the virtual address of the flag to the address of the code and injects it to the execution of the binary. As it is infecting other binaries present in that folders, when one of those binaries are executed, they will propagate as well the virus to others.

## Installation and Testing

As there is a `.devcontainer`, you can open the project with your VSCode with the appropiate extension and the Docker container will deploy automatically.

Alternatively, you can deploy it the hard mode:

```bash
docker build -t famine .
docker run -v $(pwd):/home/famine -it famine
```

Inside the container:

```bash
make && ./build/famine
```

If you want to see the syscalls and a simple test we have done:

```bash
make run
```

or to debug it:

```bash
make g
```

## Useful programs used during the process

- [Strace](https://strace.io/)
- [GDB](https://www.sourceware.org/gdb/)
- [readelf](https://man7.org/linux/man-pages/man1/readelf.1.html)
- [radare2](https://rada.re/n/radare2.html)
- [xxd](https://manpages.org/xxd)

### Resources

- [Understanding and Anlysing ELF](https://linux-audit.com/elf-binaries-on-linux-understanding-and-analysis/)
- [Midrashim's Implementation](https://samples.vx-underground.org/root/Papers/Linux/Infection/2021-01-18%20-%20ELF%20Infection%20in%20Assembly%20x64%20-%20Midrashim%20virus.pdf)
- [ELF Files](https://man7.org/linux/man-pages/man5/elf.5.html)
- [Syscall Table](https://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)
- [PT_NOTE to PT_LOAD](https://tmpout.sh/1/2.html)
- [More PT_NOTE to PT_LOAD](https://www.symbolcrash.com/2019/03/27/pt_note-to-pt_load-injection-in-elf/)
