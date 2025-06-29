package main

// for input/output formatting?
import "fmt"

// this is called a variadic function
func echo(args ...any) {
	fmt.Println(args...) // Add "..." after args to unpack args as multiple args
}

func main() {
	msg := "Hello World"
	echo(msg)
}
