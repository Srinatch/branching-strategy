function showMessage(){

    alert("Welcome to N Software Solutions!");

}

document.querySelector("form").addEventListener("submit", function(e){

    e.preventDefault();

    alert("Thank you for contacting us.");

    this.reset();

});