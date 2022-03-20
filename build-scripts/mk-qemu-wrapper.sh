#!/bin/bash
for exec in CSClient ECAgent svpnservice $extra_amd64_bins; do
	exec_path=/usr/share/sangfor/EasyConnect/resources/bin/$exec &&
	mkdir -p /usr/local/libexec/qemu-hack/ &&
	qemu_path=/usr/local/libexec/qemu-hack/$exec &&

	mv ${exec_path} ${exec_path}-origin &&

	# 一个让 qemu 产生的进程名字和原生运行时名字一致的 hack（便于 killall 杀进程）：使 qemu 的文件名和被模拟程序文件名一致
	ln -s /usr/bin/qemu-x86_64 ${qemu_path} &&

	# 将原可执行文件用 qemu 封装起来
	printf '%s\n%s\n' '#!/bin/sh' "exec ${qemu_path} \${qemu_args} ${exec_path}-origin "'"$@"' > ${exec_path} &&
	chmod +x ${exec_path} ${exec_path}-origin || exit 1
done
