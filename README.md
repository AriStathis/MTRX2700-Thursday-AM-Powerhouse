# MTRX2700-Thursday-AM-Powerhouse

Group Members:

Ari Stathis 
  - Delegator for tasks
  - Digital I/O
  - Timers
  - Integration
  
Jason Zhou 
  - Serial communication
  - Integration

Kevin Xu 
  - Serial communication
  - Integration
  
Viswada Varri 
  - Timers 
  - Integration

References for Marking:
  - PDF of flow diagrams for each module in each task for ease of explaination on presentation day
  

Instructions for the user:
  - Open each file in the STM IDE and Debug 
  
  Task 1:
    - Debug, open memory browser and run to view changes to the string
    
  Task 2:
    - Run each program, the LEDs will confirm what is executed in each task
    - Refer to flow diagrams module for ease of explaination
    
  Task 3:
    - Debug, open SFRs-USART1-TDR and run to view transmit of the string.
    - Connect two STM32F303's ground and PC4(T board) to PC11(R board), Debug R board and run. Then start running A board to transmit the string to the R board. Open memory browser of R board to check if the string is in the correct address.
    - Debug, open SFRs-USART1-TDR (R board) to view the transmit of the string. 
   
  Task 4:
    - Run each program
    - It is to be noted that task a, b and c can all be done in one program as we are running our timers in hardware by checking flags to operate the delay time
    also the equation in part a used takes in the input time and toggles how long the prescaler is such that a and b are the same. 
    
  
    
    

