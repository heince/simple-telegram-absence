#!/usr/bin/env perl6 
#===============================================================================
#
#         FILE: absence.p6
#
#        USAGE: ./absence.p6  
#
#  DESCRIPTION: main program to track staff in and out time
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Heince Kurniawan
#       EMAIL : heince.kurniawan@itgroupinc.asia
# ORGANIZATION: IT Group Indonesia
#      VERSION: 1.0
#      CREATED: 07/01/18 14:58:26
#     REVISION: ---
#===============================================================================

use v6;
use lib '/Users/heince/git/TelegramBot/lib';
use Telegram;
use lib ~$*PROGRAM.sibling: '../lib';

my $dbfile  = ~$*PROGRAM.sibling: '../db/absen.db';
my $chatid  = get_chatid();
my $token   = get_token();
my $bot     = Telegram::Bot.new($token);

my Int $offset;

sub MAIN (Int $chatid?, Str $token?)
{
    while 1
    {
        my @str;
        my $updates = get_updates();

        if $updates.elems > 0
        {
            for 0 .. ($updates.elems - 1) -> $item
            {
                say $item;
                if filter_command($updates[$item].message.text)
                {
                    write_update(parse_message($updates[$item]));
                }
                else
                {
                    warn "command not valid";
                }
            }

            set_last_id($updates[$updates.elems - 1].update_id);
            sleep 1;
        }
    }
}

sub get_chatid() of Int
{
    my $token_file = ~$*PROGRAM.sibling: '../.chatid';

    return $token_file.IO.lines[0].Int;
}

sub get_token() of Str
{
    my $token_file = ~$*PROGRAM.sibling: '../.token';

    return $token_file.IO.lines[0];
}

sub write_update (Str $str)
{
    spurt $dbfile, $str, :append;
}

sub parse_message($update) of Str
{
    my @str;

    push @str, $update.update_id;
    push @str, $update.message.date;
    push @str, $update.message.from.user-name;
    push @str, $update.message.text;

    return @str.join(',') ~ "\n";
}

sub get_updates()
{
    my $update = $bot.get-updates({offset => get_last_id()});
    return $update;
}

sub filter_command(Str $command) of Bool
{
    given $command
    {
        when '/masuk' {return True}
        when '/pulang' {return True}
        default {return False}
    }
}

sub get_last_id() of Int
{
    if $offset
    {
        return $offset;
    }
    else
    {
        my $proc = run 'tail', '-1', $dbfile, :out;
        my $result = $proc.out.slurp: :close;
        return $result.split(",")[0].Int;
    }
}

sub set_last_id (Int $id)
{
    $offset = $id + 1;
}
