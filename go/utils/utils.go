package utils

// for input/output formatting?
import "fmt"

// this is called a variadic function
// THIS FUNCTION IS NOT EXPORTED BECAUSE IT STARTS WITH LOWERCASE LETTER 'e'
func echo(args ...any) {
	fmt.Println(args...) // Add "..." after args to unpack args as multiple args
}

// ON THE OTHER HAND, THIS FUNCTION IS EXPORTED BECAUSE IT STARTS WITH A UPPERCASE LETTER 'E'
func Echo(args ...any) {
	fmt.Println(args...) // Add "..." after args to unpack args as multiple args
}

// func err(args ...any)
