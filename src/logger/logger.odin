package logger

import "core:fmt"
import "core:time"
import "base:runtime"

log_fatalf :: #force_inline proc(msg: string, args: ..any) {
	_ = fmt.eprintfln("[FATAL] : %s", fmt.tprintf(msg, args))
}

log_errorf :: #force_inline proc(msg: string, args: ..any) {
	_ = fmt.eprintfln("[ERROR] : %s", fmt.tprintf(msg, args))
}

log_infof :: #force_inline proc(msg: string, args: ..any) {
	_ = fmt.printfln("[INFO] : %s", fmt.tprintf(msg, args))
}

log_warnf :: #force_inline proc(msg: string, args: ..any) {
	_ = fmt.printfln("[WARNING] : %s", fmt.tprintf(msg, args))
}

// Formatted with passed location
log_fatalfl :: #force_inline proc(msg: string, location: runtime.Source_Code_Location, args: ..any) {
	_ = fmt.eprintfln("[FATAL] : %s at location %s", fmt.tprintf(msg, args), location)
}

log_errorfl :: #force_inline proc(msg: string, location: runtime.Source_Code_Location, args: ..any) {
	_ = fmt.eprintfln("[ERROR] : %s at location %s", fmt.tprintf(msg, args), location)
}

log_infofl :: #force_inline proc(msg: string, location: runtime.Source_Code_Location, args: ..any) {
	_ = fmt.printfln("[INFO] : %s at location %s", fmt.tprintf(msg, args), location)
}

log_warnfl :: #force_inline proc(msg: string, location: runtime.Source_Code_Location, args: ..any) {
	_ = fmt.printfln("[WARNING] : %s at location %s", fmt.tprintf(msg, args), location)
}

// Unformatted
log_fatal :: #force_inline proc(msg: string, location: string) {
	_ = fmt.eprintfln("[FATAL] : %s at location %s", msg, location)
}

log_error :: #force_inline proc(msg: string, location: string) {
	_ = fmt.eprintfln("[ERROR] : %s at location %s", msg, location)
}

log_info :: #force_inline proc(msg: string, location: string) {
	_ = fmt.printfln("[INFO] : %s at location %s", msg, location)
}

log_warn :: #force_inline proc(msg: string, location: string) {
	_ = fmt.printfln("[WARNING] : %s at location %s", msg, location)
}
