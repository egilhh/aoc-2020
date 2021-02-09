with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line; use Ada.Command_Line;
with System.Assertions; use System.Assertions;
with Ada.Containers.Hashed_Maps; use Ada.Containers;
with Ada.Characters.Handling; use Ada.Characters.Handling;
with Ada.Unchecked_Conversion;

procedure Day24 is

    type Tile is record
        X : Integer;
        Y : Integer;
        Z : Integer;
    end record;

    function "+"(T1: Tile; T2: Tile) return Tile is
    begin
        return (T1.X + T2.X, T1.Y + T2.Y, T1.Z + T2.Z);
    end;

    type Dir_Kind is (E, SE, SW, W, NW, NE);

    Dir_To_Delta : constant array (Dir_Kind) of Tile := (
       E   => (X =>  1, Y => -1, Z =>  0),
       SE  => (X =>  0, Y => -1, Z =>  1),
       SW  => (X => -1, Y =>  0, Z =>  1),
       W   => (X => -1, Y =>  1, Z =>  0),
       NW  => (X =>  0, Y =>  1, Z => -1),
       NE  => (X =>  1, Y =>  0, Z => -1)
    );

    function Tile_Hash(T: Tile) return Hash_Type is
        function Reinterpret is new Ada.Unchecked_Conversion(Integer, Hash_Type);
        Result : Hash_TYpe := Reinterpret(T.X);
    begin
        Result := Result * 31 + Reinterpret(T.Y);
        Result := Result * 97 + Reinterpret(T.Z);
        return Result; -- Hash_TYpe is already a modular type, no mod neccessary
    end;

    package Floor is new Ada.Containers.Hashed_Maps
        (Key_Type => Tile,
         Element_Type => Boolean,
         Hash => Tile_Hash,
         Equivalent_Keys => "=");

    function Is_Black(F: in Floor.Map; T: Tile) return Boolean is
        C: Floor.Cursor := Floor.Find(F, T);
    begin
        return Floor.Has_Element(C) and then Floor.Element(C);
    end;

    function Count_Neighbours(F: in Floor.Map; T: Tile) return Integer is
        Result: Integer := 0;
    begin
        for Dir of Dir_To_Delta loop
            if Is_Black(F, T + Dir) then
                Result := Result + 1;
            end if;
        end loop;
        return Result;
    end;

    procedure Set_Tile(F: in out Floor.Map; T: Tile; Value: Boolean) is
    begin
        Floor.Include(F, T, Value);
        Ensure_Neighbours_Exist: for Dir of Dir_To_Delta loop
            if not F.Contains(T+Dir) then
                F.Insert(T+Dir, False);
            end if;
        end loop Ensure_Neighbours_Exist;
    end;

    procedure Flip_Tile(F: in out Floor.Map; T: Tile) is
        D: Floor.Cursor := Floor.Find(F, T);
    begin
        Set_Tile(F, T, (not Floor.Has_Element(D)) or else (not Floor.Element(D)));
    end;


    procedure Next_Floor(F1: in Floor.Map; F2: out Floor.Map) is
        T : Tile;
        Neighbours : Integer;
    begin
        for C in Floor.Iterate(F1) loop
            T := Floor.Key(C);
            Neighbours := Count_Neighbours(F1, T);
            if Is_Black(F1, T) then
                Set_Tile(F2, T, not (Neighbours = 0 or Neighbours > 2));
            else
                Set_Tile(F2, T, Neighbours = 2);
            end if;
        end loop;
    end;

    function Count_Black(F: in Floor.Map) return Integer is
        Result: Integer := 0;
    begin
        for T of F loop
            if T then
                Result := Result + 1;
            end if;
        end loop;
        
        -- in next version of Ada for-loops can have filters:
        -- for T of F when T loop
        --      Result := Result + 1;
        -- end loop;
        
        return Result;
    end;

    function Tile_Image(T: Tile) return String is
    begin
        return "(" & T.X'Image & ", " & T.Y'Image & ", " & T.Z'Image & ")";
    end;

    function Next_Dir(Desc: String) return Dir_Kind is
    begin
        for Dir in Dir_Kind loop
           declare
              Dir_Str : constant String := To_Lower (Dir'IMage);
           begin
              if Dir_Str'Length <= Desc'Length then
                 if Desc (Desc'First .. Desc'First + Dir_Str'Length - 1) = Dir_Str then
                    return Dir;
                 end if;
              end if;
           end;
        end loop;

        Raise_Assert_Failure("Unreachable. Could not get the next direction from " & Desc);
    end Next_Dir;

    function Parse_Tile(Input: String) return Tile is
        Result : Tile := (X => 0, Y => 0, Z => 0);
        Dir: Dir_Kind;
        First : Natural := Input'First;
    begin
        while First <= Input'Last loop
            Dir := Next_Dir(Input(First..Input'Last));
            First := First + Dir'Image'Length;
            Result := Result + Dir_To_Delta (Dir);
        end loop;

        return Result;
    end Parse_Tile;

    procedure Floor_From_File(File_Path: String; F: out Floor.Map) is
        File : File_Type;
        T : Tile;
    begin
        Open(File => File,
             Mode => In_File,
             Name => File_Path);
        while not End_Of_File(File) loop
            T := Parse_Tile(Get_Line(File));
            Flip_Tile(F, T);
        end loop;
        Close(File);
    end;

    function Part1(File_Path: String) return Integer is
        F : Floor.Map;
    begin
        Floor_From_File(File_Path, F);
        return Count_Black(F);
    end;

    function Part2(File_Path: String) return Integer is
        F : array (0..1) of Floor.Map;
        Current : Integer := 0;
    begin
        Floor_From_File(File_Path, F(Current));
        for i in 1..100 loop
            Next_Floor(F(Current), F(1 - Current));
            Current := 1 - Current;
        end loop;
        return Count_Black(F(Current));
    end;

    procedure Solve_File(File_Path: String) is
    begin
        Put_Line("Input file: " & File_Path);
        Put_Line("  Part 1:" & Integer'Image(Part1(File_Path)));
        Put_Line("  Part 2:" & Integer'Image(Part2(File_Path)));
    end Solve_File;

begin
    Put_Line("Amount of args: " & Integer'Image(Argument_Count));
    for Arg in 1..Argument_Count loop
        Solve_File(Argument(Arg));
    end loop;
end Day24;
