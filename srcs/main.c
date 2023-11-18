#include <famine.h>

#if defined(__LP64__)
        #define ElfW(type) Elf64_ ## type
#else
        #define ElfW(type) Elf32_ ## type
#endif

void read_elf_header(const char* elfFile)
{
	ElfW(Ehdr) header;
	FILE* file;

	if ((file = fopen(elfFile, "rb")))
	{
		fread(&header, sizeof(header), 1, file);

		if (memcmp(header.e_ident, ELFMAG, SELFMAG) == 0)
			printf("Valid ELF file: %s\n", elfFile);
		else
			printf("Invalid ELF file: %s\n", elfFile);

		fclose(file);
	}
}

int	main(void)
{
	DIR				*d;
	struct dirent	*dir;
	d = opendir(".");
	if (d)
	{
		while ((dir = readdir(d)))
			read_elf_header(dir->d_name);
		closedir(d);
	}
	return(0);
}
