#include <famine.h>

#if defined(__LP64__)
        #define ElfW(type) Elf64_ ## type
#else
        #define ElfW(type) Elf32_ ## type
#endif

void	read_elf_file(FILE *elf_file, ElfW(Ehdr) *header)
{
	char	ptr[100];
	printf("%s\n", header->e_ident);
	printf("%lu\n", header->e_entry);
	while(fgets(ptr, 100, elf_file)) {
		printf("%s", ptr);
	}
}

void	read_elf_header(const char* elfFile)
{
	ElfW(Ehdr)	header;
	FILE		*file;

	if ((file = fopen(elfFile, "rb")))
	{
		fread(&header, sizeof(header), 1, file);
		if (memcmp(header.e_ident, ELFMAG, SELFMAG) == 0)
			read_elf_file(file, &header);
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
