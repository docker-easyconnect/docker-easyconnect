#!/bin/sh
. /tmp/build-scripts/get-echost-names.sh &&
{
! is_echost_foreign ||
for exec in CSClient ECAgent svpnservice $extra_bins; do
	exec_path=/usr/share/sangfor/EasyConnect/resources/bin/$exec &&
	mkdir -p /usr/local/libexec/qemu-hack/ &&
	qemu_path=/usr/local/libexec/qemu-hack/$exec &&

	mv ${exec_path} ${exec_path}-origin &&

	# 一个让 qemu 产生的进程名字和原生运行时名字一致的 hack（便于 killall 杀进程）：使 qemu 的文件名和被模拟程序文件名一致
	ln -s /usr/bin/${ecqemu} ${qemu_path} &&

	# 将原可执行文件用 qemu 封装起来
	printf '%s\n%s' \
		'#!/bin/sh' \
		"LD_PRELOAD= exec ${qemu_path} -E LD_PRELOAD=\"\${LD_PRELOAD}\" ${exec_path}-origin \"\$@\"" > ${exec_path} &&
	chown --reference=${exec_path}-origin ${exec_path} &&
	chmod --reference=${exec_path}-origin ${exec_path} ||
	exit 1
done
}
