#include <cstdlib>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <set>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <stdio.h>
using namespace std;



class Command{
public:
    pid_t pid;
    vector <string> args;
    string out_redirection;
    string in_redirection;
    int pipe_from = 0;
    int pipe_to = 0;
    Command(){};
};



void parse_and_run_command(const std::string &command) {
    // TODO: Implement this.
    // Note that this is not the correct way to test for the exit command.
    // For example the command `exit` should also exit your shell.


    istringstream iss (command);
    string token = "";
    vector<Command> cs;
    set<string> special_char;
    special_char.insert(">");
    special_char.insert("|");
    special_char.insert("<");
    Command temp;
    bool path = true;
    while(iss >> token) {
        if (token == "|") {
            if (!temp.args.size()) {
                std::cerr << "Invalid command\n";
                return;
            }
            temp.pipe_to = 1;
            cs.push_back(temp);
            temp = Command();
            temp.pipe_from = 1;

        } else if (token == ">") {
            string target = "";
            if (!(iss >> target) || special_char.count(target)) {
                cerr << "invalid command\n";
                return;
            } else {
                temp.out_redirection = target;
            }

        } else if (token == "<") {
            string target = "";
            if(!(iss >> target) || special_char.count(target)){
                cerr << "invalid command\n";
                return;
            }else{

                temp.in_redirection = target;
            }

        } else {
            temp.args.push_back(token);
        }
    }
    // check if command is empty
    cs.push_back(temp);

    for(Command c : cs){
        if(!c.args.size()){
            cerr << "invalid command\n";
            return;
        }
    }



    int fd[2];
    vector<pid_t> parentPids;
    for(auto ptr = cs.begin(); ptr != cs.end(); ptr++){
        Command& c = *ptr;


        if (c.args[0] == "exit") {
            exit(0);
        }

        if(c.pipe_from){
            c.pipe_from = fd[0];
        }
        if(c.pipe_to){
            if(pipe(fd) == -1){
                perror("Create pipe error");
                return;
            }
            c.pipe_to = fd[1];
        }

        c.pid = fork();
        if(c.pid < 0){
            if(c.pipe_from){
                close(c.pipe_from);
            }
            if(c.pipe_to){
                close(fd[0]);
                close(fd[1]);
            }
            perror("fork command error");
            return;
        }
        else if(c.pid == 0) {
            // construct pipeline
            if(c.pipe_from){
                dup2(c.pipe_from,STDIN_FILENO);
                close(c.pipe_from);
            }
            if(c.pipe_to){
                close(fd[0]);
                dup2(c.pipe_to, STDOUT_FILENO);
                close(c.pipe_to);
            }

            //redirection

            if(c.in_redirection != ""){
                int in_fd = open(&c.in_redirection[0], O_RDONLY);
                if(in_fd == -1){
                    perror(("Cannot read file " + c.in_redirection).c_str());
                    exit(1);
                }
                dup2(in_fd, 0);
            }

            if(c.out_redirection != ""){
                int out_fd = open(&c.out_redirection[0], O_WRONLY | O_CREAT | O_TRUNC, 0777);
                dup2(out_fd,1);
            }

            vector<char*> args;
            for(int i = 0; i < (int)c.args.size(); i++){
                args.push_back(&c.args[i][0]);
            }
            args.push_back(NULL);
            execv(&c.args[0][0], args.data());
            perror("Cannot execute ");
            exit(1);
        } else {

            if(c.pipe_to) {
                close(c.pipe_to);
            }
            if(c.pipe_from){
                close(c.pipe_from);
            }
            //parentPids.push_back(pid);
        }

    }
    for (auto ptr = cs.begin(); ptr != cs.end(); ptr++){
        int status;
        waitpid(ptr->pid,&status,0);
        std::cout << "> Exit status: " << WEXITSTATUS(status)<< "\n";
    }

}




int main(void) {
    while (true) {
        std::string command;
        std::cout << "> ";
        std::getline(std::cin, command);
        parse_and_run_command(command);

    }
    return 0;
}