package linux

import "core:c"
import "core:strings"
import "core:os"
import "core:fmt"

foreign import libc "system:c"

pid_t :: #type u32;
uid_t :: #type u32;
gid_t :: #type u32;

passwd :: struct {
	pw_name: cstring,
	pw_passwd: cstring,
	pw_uid: uid_t,
	pw_gid: gid_t,
	pw_gecos: cstring,
	pw_dir: cstring,
	pw_shell: cstring,
}

DIR :: #opaque [0]byte;
ino_t :: distinct c.ulong;
off_t :: distinct c.long;

// NOTE: The only fields in the dirent structure that are mandated by POSIX.1 are d_name and d_ino.  The other fields are unstandardized, and not present on all systems.
// See Notes in `man 3 readdir` for more info about structure and size of structure.
dirent :: struct { // TODO: Make this a raw version and another struct that's easier to use.
	d_ino: ino_t, // Inode number of the file
	d_off: off_t,
	d_reclen: c.ushort, // Size in bytes of the returned record
	d_type: c.uchar, // File type
	
	d_name: [256]c.char, // Name of file, null-terminated, can exceede 256 chars (in which case d_reclen exceedes the size of this struct)
}

// -- termios stuff --
cc_t :: distinct c.uchar;
speed_t :: distinct c.uint;
tcflag_t :: distinct c.uint;

NCCS :: 32;
termios :: struct {
	c_iflag: tcflag_t,  // Input modes
	c_oflag: tcflag_t,  // Output modes
	c_cflag: tcflag_t,  // Control modes
	c_lflag: tcflag_t,  // Local modes
	c_line: cc_t,
	c_cc: [NCCS]cc_t,    // Special characters
	c_ispeed: speed_t,  // Input speed
	c_ospeed: speed_t   // Output speed
}

/* c_cc characters */
VINTR :: 0;
VQUIT :: 1;
VERASE :: 2;
VKILL :: 3;
VEOF :: 4;
VTIME :: 5;
VMIN :: 6;
VSWTC :: 7;
VSTART :: 8;
VSTOP :: 9;
VSUSP :: 10;
VEOL :: 11;
VREPRINT :: 12;
VDISCARD :: 13;
VWERASE :: 14;
VLNEXT :: 15;
VEOL2 :: 16;

/* c_iflag bits */
IGNBRK: tcflag_t : 0000001;
BRKINT: tcflag_t : 0000002;
IGNPAR: tcflag_t : 0000004;
PARMRK: tcflag_t : 0000010;
INPCK: tcflag_t : 0000020;
ISTRIP: tcflag_t : 0000040;
INLCR: tcflag_t : 0000100;
IGNCR: tcflag_t : 0000200;
ICRNL: tcflag_t : 0000400;
IUCLC: tcflag_t : 0001000;
IXON: tcflag_t : 0002000;
IXANY: tcflag_t : 0004000;
IXOFF: tcflag_t : 0010000;
IMAXBEL :: 0020000;
IUTF8 :: 0040000;

/* c_oflag bits */
OPOST :: 0000001;
OLCUC :: 0000002;
ONLCR :: 0000004;
OCRNL :: 0000010;
ONOCR :: 0000020;
ONLRET :: 0000040;
OFILL :: 0000100;
OFDEL :: 0000200;
/*#if defined __USE_MISC || defined __USE_XOPEN
# define NLDLY        0000400
# define   NL0        0000000
# define   NL1        0000400
# define CRDLY        0003000
# define   CR0        0000000
# define   CR1        0001000
# define   CR2        0002000
# define   CR3        0003000
# define TABDLY        0014000
# define   TAB0        0000000
# define   TAB1        0004000
# define   TAB2        0010000
# define   TAB3        0014000
# define BSDLY        0020000
# define   BS0        0000000
# define   BS1        0020000
# define FFDLY        0100000
# define   FF0        0000000
# define   FF1        0100000
#endif*/
VTDLY :: 0040000;
VT0 :: 0000000;
VT1 :: 0040000;
/*#ifdef __USE_MISC
# define XTABS        0014000
#endif*/

/* c_cflag bit meaning */
/*#ifdef __USE_MISC
# define CBAUD        0010017
#endif*/
B0 :: 0000000;                /* hang up */
B50 :: 0000001;
B75 :: 0000002;
B110 :: 0000003;
B134 :: 0000004;
B150 :: 0000005;
B200 :: 0000006;
B300 :: 0000007;
B600 :: 0000010;
B1200 :: 0000011;
B1800 :: 0000012;
B2400 :: 0000013;
B4800 :: 0000014;
B9600 :: 0000015;
B19200 :: 0000016;
B38400 :: 0000017;
// #ifdef __USE_MISC
// # define EXTA B19200
// # define EXTB B38400
// #endif
CSIZE :: 0000060;
CS5 :: 0000000;
CS6 :: 0000020;
CS7 :: 0000040;
CS8 :: 0000060;
CSTOPB :: 0000100;
CREAD :: 0000200;
PARENB :: 0000400;
PARODD :: 0001000;
HUPCL :: 0002000;
CLOCAL :: 0004000;
// #ifdef __USE_MISC
// # define CBAUDEX 0010000
// #endif
B57600 :: 0010001;
B115200 :: 0010002;
B230400 :: 0010003;
B460800 :: 0010004;
B500000 :: 0010005;
B576000 :: 0010006;
B921600 :: 0010007;
B1000000 :: 0010010;
B1152000 :: 0010011;
B1500000 :: 0010012;
B2000000 :: 0010013;
B2500000 :: 0010014;
B3000000 :: 0010015;
B3500000 :: 0010016;
B4000000 :: 0010017;
__MAX_BAUD :: B4000000;
// #ifdef __USE_MISC
// # define CIBAUD          002003600000                /* input baud rate (not used) */
// # define CMSPAR   010000000000                /* mark or space (stick) parity */
// # define CRTSCTS  020000000000                /* flow control */
// #endif

/* c_lflag bits */
ISIG :: 0000001;
ICANON: tcflag_t : 0000002;
// #if defined __USE_MISC || (defined __USE_XOPEN && !defined __USE_XOPEN2K)
// # define XCASE        0000004
// #endif
ECHO: tcflag_t : 0000010;
ECHOE :: 0000020;
ECHOK :: 0000040;
ECHONL :: 0000100;
NOFLSH :: 0000200;
TOSTOP :: 0000400;
/*#ifdef __USE_MISC
# define ECHOCTL 0001000
# define ECHOPRT 0002000
# define ECHOKE         0004000
# define FLUSHO         0010000
# define PENDIN         0040000
#endif*/
IEXTEN :: 0100000;
/*#ifdef __USE_MISC
# define EXTPROC 0200000
#endif*/

TCSANOW :: 0;
TCSADRAIN :: 1;
TCSAFLUSH :: 2;

// -- ioctl --
winsize :: struct {
	ws_row: c.ushort,
	ws_col: c.ushort,
	ws_xpixel: c.ushort,
	ws_ypixel: c.ushort,
}

TIOCGWINSZ :: 21523;

// wait & waitpid Options
WNOHANG :: 1;    // Return immediately if no child has exited
WUNTRACED :: 2;  // Also return if a child has stopped (but not traced via ptrace).
WCONTINUED :: 8; // Also return if a stopped child has been resumed by delivery of SIGCONT

WIFEXITED :: inline proc(status: int) -> bool {
	return (((status) & 0x7f) == 0);
}

WIFSIGNALED :: inline proc(status: int) -> bool {
	return (((byte) (((status) & 0x7f) + 1) >> 1) > 0);
}

// Signal Handling

sighandler_t :: #type proc "c" (signum: c.int);
SIG_IGN : uintptr : 1;
SIG_DFL : uintptr : 0;
SIG_ERR : uintptr : ~uintptr(0); // -1

/* ISO C99 signals.  */
SIGINT :: 2;        /* Interactive attention signal.  */
SIGILL :: 4;        /* Illegal instruction.  */
SIGABRT :: 6;        /* Abnormal termination.  */
SIGFPE :: 8;        /* Erroneous arithmetic operation.  */
SIGSEGV :: 11;        /* Invalid access to storage.  */
SIGTERM :: 15;        /* Termination request.  */
/* Historical signals specified by POSIX. */
SIGHUP :: 1;        /* Hangup.  */
SIGQUIT :: 3;        /* Quit.  */
SIGTRAP :: 5;        /* Trace/breakpoint trap.  */
SIGKILL :: 9;        /* Killed.  */
// SIGBUS :: 10;        /* Bus error.  */
// SIGSYS :: 12;        /* Bad system call.  */
SIGPIPE :: 13;        /* Broken pipe.  */
SIGALRM :: 14;        /* Alarm clock.  */
/* New(er) POSIX signals (1003.1-2008, 1003.1-2013).  */
// SIGURG :: 16;        /* Urgent data is available at a socket.  */
// SIGSTOP :: 17;        /* Stop, unblockable.  */
// SIGTSTP :: 18;        /* Keyboard stop.  */
// SIGCONT :: 19;        /* Continue.  */
SIGCHLD_ISO :: 20;        /* Child terminated or stopped.  */
SIGTTIN :: 21;        /* Background read from control terminal.  */
SIGTTOU :: 22;        /* Background write to control terminal.  */
SIGPOLL_ISO :: 23;        /* Pollable event occurred (System V).  */
SIGXCPU :: 24;        /* CPU time limit exceeded.  */
SIGXFSZ :: 25;        /* File size limit exceeded.  */
SIGVTALRM :: 26;        /* Virtual timer expired.  */
SIGPROF :: 27;        /* Profiling timer expired.  */
// SIGUSR1 :: 30;        /* User-defined signal 1.  */
// SIGUSR2 :: 31;        /* User-defined signal 2.  */
/* Nonstandard signals found in all modern POSIX systems
   (including both BSD and Linux).  */
SIGWINCH :: 28;        /* Window size change (4.3 BSD, Sun).  */
/* Archaic names for compatibility.  */
SIGIO :: SIGPOLL_ISO;        /* I/O now possible (4.2 BSD).  */
SIGIOT :: SIGABRT;        /* IOT instruction, abort() on a PDP-11.  */
SIGCLD :: SIGCHLD_ISO;        /* Old System V name */

// Signal Adjustment for Linux
SIGSTKFLT :: 16;        /* Stack fault (obsolete).  */
SIGPWR :: 30;        /* Power failure imminent.  */
SIGBUS :: 7;
SIGUSR1 :: 10;
SIGUSR2 :: 12;
SIGCHLD :: 17;
SIGCONT :: 18;
SIGSTOP :: 19;
SIGTSTP :: 20; /* terminal stop - Ctrl+Z */
SIGURG :: 23;
SIGPOLL :: 29;
SIGSYS :: 31;

foreign libc {
@(link_name="getuid") getuid :: proc() -> uid_t ---;
@(link_name="getpwnam") _unix_getpwnam :: proc(name: cstring) -> ^passwd ---;
@(link_name="getpwuid") getpwuid :: proc(uid: uid_t) -> ^passwd ---;
@(link_name="readlink") _unix_readlink :: proc(pathname: cstring, buf: cstring, bufsiz: c.size_t) -> c.ssize_t ---;
	
@(link_name="opendir") _unix_opendir :: proc(name: cstring) -> ^DIR ---; // TODO: Returns ^DIR (which is defined as __dirstream in dirent.h)
@(link_name="readdir") _unix_readdir :: proc(dirp: ^DIR) -> ^dirent ---;
@(link_name="closedir") _unix_closedir :: proc(dirp: ^DIR) -> c.int ---;
	
@(link_name="setenv") _unix_setenv :: proc(name: cstring, value: cstring, overwrite: c.int) -> c.int ---;
@(link_name="unsetenv") _unix_unsetenv :: proc(name: cstring) -> c.int ---;
@(link_name="secure_getenv") _unix_secure_getenv :: proc(name: cstring) -> cstring ---; // NOTE: GNU-specific
	
@(link_name="tcgetattr") _unix_tcgetattr :: proc(fd: os.Handle, termios_p: ^termios) -> c.int ---;
@(link_name="tcsetattr") _unix_tcsetattr :: proc(fd: os.Handle, optional_actions: c.int, termios_p: ^termios) -> c.int ---;
	
@(link_name="ioctl") _unix_ioctl :: proc(fd: os.Handle, request: c.ulong, argp: rawptr) -> c.int ---;
	
@(link_name="fork") fork :: proc() -> pid_t ---;
@(link_name="execvp") _unix_execvp :: proc(file: cstring, argv: ^cstring) -> c.int ---;
@(link_name="waitpid") _unix_waitpid :: proc(pid: pid_t, wstatus: ^c.int, options: c.int) -> pid_t ---;
	
@(link_name="signal") _unix_signal :: proc(signum: c.int, handler: c.uintptr_t) -> c.uintptr_t ---;
}

getpwnam :: proc(name: string) -> ^passwd {
	cstr := strings.clone_to_cstring(name);
	defer delete(cstr);
	return _unix_getpwnam(cstr);
}

readlink :: proc(pathname: string, buf: []u8) -> (int, os.Errno) {
	cstr_pathname := strings.clone_to_cstring(pathname);
	defer delete(cstr_pathname);
	bytes_written := _unix_readlink(cstr_pathname, cstring(#no_bounds_check &buf[0]), c.size_t(len(buf)));
	if bytes_written == -1 {
		return -1, os.Errno(os.get_last_error());
	}
	return int(bytes_written), os.ERROR_NONE;
}

opendir :: proc(name: string) -> (^DIR, os.Errno) {
	cstr := strings.clone_to_cstring(name);
	defer delete(cstr);
	result := _unix_opendir(cstr);
	if result == nil {
		return nil, os.Errno(os.get_last_error());
	}
	return result, os.ERROR_NONE;
}

readdir :: proc(dirp: ^DIR) -> (^dirent, os.Errno) {
	previous := os.Errno(os.get_last_error());
	
	result := _unix_readdir(dirp);
	err := os.Errno(os.get_last_error());
	
	if result == nil && previous != err { // If nil and errno changed, err occured
		return nil, err;
	} else if result == nil { // If errno not changed, end of directory stream
		return nil, os.ERROR_NONE;
	}
	
	return result, os.ERROR_NONE;
}

closedir :: proc(dirp: ^DIR) -> os.Errno {
	result := _unix_closedir(dirp);
	if result == 0 {
		return os.ERROR_NONE;
	} else {
		return os.Errno(os.get_last_error());
	}
}

setenv :: proc(name: string, value: string, overwrite: bool) -> os.Errno {
	name_str := strings.clone_to_cstring(name);
	defer delete(name_str);
	value_str := strings.clone_to_cstring(value);
	defer delete(value_str);
	result := _unix_setenv(name_str, value_str, overwrite ? 1 : 0);
	if result == -1 {
		return os.Errno(os.get_last_error());
	}
	
	return os.ERROR_NONE;
}

unsetenv :: proc(name: string) -> os.Errno {
	name_str := strings.clone_to_cstring(name);
	defer delete(name_str);
	result := _unix_unsetenv(name_str);
	if result == -1 {
		return os.Errno(os.get_last_error());
	}
	
	return os.ERROR_NONE;
}

// NOTE: GNU-specific
secure_getenv :: proc(name: string) -> (string, bool) {
	path_str := strings.clone_to_cstring(name);
	defer delete(path_str);
	cstr := _unix_secure_getenv(path_str);
	if cstr == nil {
		return "", false;
	}
	return string(cstr), true;
}

tcgetattr :: proc(fd: os.Handle, termios_p: ^termios) -> os.Errno {
	result := _unix_tcgetattr(fd, termios_p);
	if result == -1 {
		return os.Errno(os.get_last_error());
	}
	
	return os.ERROR_NONE;
}

tcsetattr :: proc(fd: os.Handle, optional_actions: int, termios_p: ^termios) -> os.Errno {
	result := _unix_tcsetattr(fd, c.int(optional_actions), termios_p);
	if result == -1 {
		return os.Errno(os.get_last_error());
	}
	
	return os.ERROR_NONE;
}

ioctl :: proc(fd: os.Handle, request: u64, argp: rawptr) -> (int, os.Errno) {
	result := _unix_ioctl(fd, c.ulong(request), argp);
	if result == -1 {
		return -1, os.Errno(os.get_last_error());
	}
	
	return int(result), os.ERROR_NONE;
}

/*execvp :: proc(file: string, args: []string) -> os.Errno {
	file_str := strings.clone_to_cstring(file);
	defer delete(file_str);

	result := _unix_execvp(file_str, );
	if result == -1 {
		return os.Errno(os.get_last_error());
	}

	return os.ERROR_NONE;
}*/

waitpid :: proc(pid: pid_t, wstatus: ^int, options: int) -> pid_t {
	return _unix_waitpid(pid, cast(^c.int) wstatus, c.int(options));
}

signal_handler :: proc(signum: int, handler: sighandler_t) -> (uintptr, os.Errno) {
	result := _unix_signal(c.int(signum), c.uintptr_t(uintptr(rawptr(handler))));
	if c.uintptr_t(result) == c.uintptr_t(SIG_ERR) {
		return uintptr(result), os.Errno(os.get_last_error());
	}
	
	return uintptr(result), os.ERROR_NONE;
}

signal_int :: proc(signum: int, handler: uintptr) -> (uintptr, os.Errno) {
	result := _unix_signal(c.int(signum), c.uintptr_t(handler));
	if result == SIG_ERR {
		return uintptr(result), os.Errno(os.get_last_error());
	}
	
	return uintptr(result), os.ERROR_NONE;
}

signal :: proc{signal_handler, signal_int};

// TODO: Doesn't work on any BSDs or MacOS
// TODO: Look at 'realpath'
get_executable_path :: proc() -> string {
	pathname :: "/proc/self/exe";
	page_size := os.get_page_size();
	buf := make([dynamic]u8, page_size);
	
	// Credit for this loop technique: Tetralux
	for {
		bytes_written, error := readlink(pathname, buf[:]);
		if error == os.ERROR_NONE {
			resize(&buf, bytes_written);
			return string(buf[:]);
		}
		if error != os.ERANGE {
			return "";
		}
		resize(&buf, len(buf)+page_size);
	}
	unreachable();
}

get_path_separator :: proc() -> rune {
	return '/';
}

