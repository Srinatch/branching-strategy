# This is a simple Python program to print "Hello, World!"

def main():
    try:
        # Print the message to the console
        print("Hello, World!")
    except Exception as e:
        # Handle any unexpected errors
        print(f"An error occurred: {e}")

# Entry point of the program
if __name__ == "__main__":
    main()
