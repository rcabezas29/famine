#include <famine.h>

void	read_elf_file(FILE *elf_file, uint16_t n_pheaders, uint16_t pheader_size)
{
	Elf64_Phdr	prog_header;

	printf("SIZE: %i - N: %i\n", pheader_size, n_pheaders);

	while (n_pheaders--)
	{
		fread(&prog_header, pheader_size, 1, elf_file);
		if (prog_header.p_type == PT_NOTE) {
			printf("PT_NOTE %u\n", prog_header.p_type);
		}
		else if (prog_header.p_type == PT_LOAD) {
			printf("PT_LOAD %u\n", prog_header.p_type);
		} else {
			printf("OTHER %u\n", prog_header.p_type);
		}

	}
}

void	read_elf_header(const char* elfFile)
{
	Elf64_Ehdr	header;
	FILE		*file;

	if ((file = fopen(elfFile, "rb")))
	{
		fread(&header, sizeof(header), 1, file);
		if (memcmp(header.e_ident, ELFMAG, SELFMAG) == 0)
			read_elf_file(file, header.e_phnum, header.e_phentsize);
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
